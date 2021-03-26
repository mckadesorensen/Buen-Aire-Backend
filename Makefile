SELF_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

export TF_VAR_DEPLOY_NAME=${DEPLOY_NAME}
export TF_VAR_AWS_ID_LAST_FOUR=${AWS_ID_LAST_FOUR}
export TF_VAR_DIST_DIR=${SELF_DIR}

.DEFAULT_GOAL := workflow
.SILENT:
.ONESHELL:
.PHONY: all workflow


# ----------------- Start of Docker Commands -----------------
image: Build/buen_aire_backend.Dockerfile
	cd Build && \
	docker build -f buen_aire_backend.Dockerfile -t buen_aire_backend .

container-shell:
	docker run -it --rm \
		--user `id -u` \
		-v ${PWD}:/Buen-Aire-Backend \
		-v ~/.aws:/.aws \
		buen_aire_backend

# ----------------- Start of Docker Commands -----------------


# ----------------- Start of Terraform Commands -----------------
${SELF_DIR}/process_lambda.zip: ${SELF_DIR} workflow/lambdas/process_data.py
	cd workflow/lambdas
	zip ${SELF_DIR}/process_lambda.zip process_data.py

${SELF_DIR}/egress_lambda.zip: ${SELF_DIR} workflow/lambdas/egress_data.py
	cd workflow/lambdas
	zip ${SELF_DIR}/egress_lambda.zip egress_data.py

${SELF_DIR}/lambda_dependencies_layer.zip: ${SELF_DIR} Build/requirements.txt
	mkdir -p ${SELF_DIR}/python
	cd ${SELF_DIR}/python
	pip3 install -r ${SELF_DIR}/Build/requirements.txt --target .
	cd ..
	zip -r ${SELF_DIR}/lambda_dependencies_layer.zip python/*

artifacts: ${SELF_DIR}/lambda_dependencies_layer.zip ${SELF_DIR}/process_lambda.zip ${SELF_DIR}/egress_lambda.zip

terraform-init:
	cd tf
	rm -rf terraform.tfstate.d
	rm -f .terraform/environment
	terraform init -reconfigure -input=false
	terraform workspace new "buen-aire" 2>/dev/null || terraform workspace select "buen-aire"

tf: terraform-init
	cd tf
	terraform import -input=false aws_s3_bucket.backend-tf-state-bucket ${DEPLOY_NAME}-buen-aire-tf-state-${AWS_ID_LAST_FOUR} 2>/dev/null || true
	terraform import -input=false aws_dynamodb_table.backend-tf-locks-table ${DEPLOY_NAME}-buen-aire-tf-locks 2>/dev/null || true
	terraform apply -input=false -auto-approve

workflow-init:
	cd workflow
	rm -f .terraform/environment
	terraform init -reconfigure -input=false \
		-backend-config "region=${AWS_REGION}" \
		-backend-config "bucket=${DEPLOY_NAME}-buen-aire-tf-state-${AWS_ID_LAST_FOUR}" \
		-backend-config "key=workflow/terraform.tfstate" \
		-backend-config "dynamodb_table=${DEPLOY_NAME}-buen-aire-tf-locks"
	terraform workspace new ${DEPLOY_NAME} 2>/dev/null || terraform workspace select ${DEPLOY_NAME}

workflow: artifacts workflow-init
	cd workflow
	terraform apply -input=false -auto-approve

all: tf workflow
# ----------------- End of Terraform Commands -----------------