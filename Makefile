export TF_VAR_DEPLOY_NAME=${DEPLOY_NAME}

.SILENT:
.ONESHELL:
.PHONY:


# Docker Commands
image: Build/buen_aire_backend.Dockerfile
	cd Build && \
	docker build -f buen_aire_backend.Dockerfile -t buen_aire_backend .

container-shell:
	docker run -it --rm \
		--user `id -u` \
		-v ${PWD}:/Buen-Aire-Backend \
		-v ~/.aws:/.aws \
		buen_aire_backend

# Terraform Commands
# TODO: Make terraform commands and apply vars to variables.tf
terraform-init:
	cd tf
	rm -rf terraform.tfstate.d
	terraform init
	terraform workspace new "buen-aire" 2>/dev/null || terraform workspace select "buen-aire"

tf: terraform-init
	cd tf
	terraform import -input=false aws_s3_bucket.backend-tf-state-bucket ${DEPLOY_NAME}-buen-aire-tf-state-${AWS_ID_LAST_FOUR} 2>/dev/null || true
	terraform import -input=false aws_dynamodb_table.backend-tf-locks-table ${DEPLOY_NAME}-buen-aire-tf-locks 2>/dev/null || true
	terraform apply -input=false -auto-approve -no-color

init:
	cd workflow
	terraform init reconfigure -input=false -no-color \
		-backend-config "region=${AWS_REGION}" \
		-backend-config "bucket=${DEPLOY_NAME}-buen-aire-tf-state-${AWS_ID_LAST_FOUR}" \
		-backed-config "key=workflow/terraform.tfstate" \
		-backend-config "dynamodb_table=${DEPLOY_NAME}-buen-aire-tf-locks"
	terraform workspace new ${DEPLOY_NAME} 2>/dev/null || terraform workspace select ${DEPLOY_NAME}

# TODO: Zip the lambdas and upload them to s3