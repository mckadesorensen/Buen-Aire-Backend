terraform {
  required_providers {
    aws = "~> 3.19.0"
  }
}

provider "aws"{}

data "aws_caller_identity" "current" {}

locals {
  prefix = "${var.DEPLOY_NAME}-buen-aire"
  aws_account_id       = data.aws_caller_identity.current.account_id
  aws_id_last_four = substr(data.aws_caller_identity.current.account_id, -4, 4)
}

resource "aws_s3_bucket" "tf-state-bucket" {
  bucket = "${local.prefix}-buen-aire-tf-state-${local.aws_id_last_four}"
  versioning {
    enabled = true
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "tf-locks-table" {
  hash_key = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  name = "${local.prefix}-buen-aire-tf-locks"
  attribute {
    name = "LockID"
    type = "S"
  }
  lifecycle {
    prevent_destroy = true
  }
}