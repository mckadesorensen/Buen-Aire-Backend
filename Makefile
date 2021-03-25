export TF_VAR_DEPLOY_NAME=${DEPLOY_NAME}
export TF_VAR_AWS_ID_LAST_FOUR=${AWS_ID_LAST_FOUR}

.DEFAULT_GOAL := all
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
# TODO: Make terraform commands and apply vars to variables.tf
upload-lambdas:
	zip lambdas.zip workflow/lambdas/*.py
	aws --profile ${AWS_PROFILE} s3 cp ${PWD}/lambdas.zip s3://${DEPLOY_NAME}-buen-aire-lambda-code-${AWS_ID_LAST_FOUR}/lambdas.zip

terraform-init:
	cd tf
	rm -rf terraform.tfstate.d
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

workflow: upload-lambdas workflow-init
	cd workflow
	terraform apply  -input=false -auto-approve

# TODO: Zip the lambdas and upload them to s3

all: tf workflow

# ----------------- End of Terraform Commands -----------------