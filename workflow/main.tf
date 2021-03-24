terraform {
  backend "s3"{}
}

provider "aws" {}

locals {
  prefix = "${var.DEPLOY_NAME}-buen-aire-"
  python_version = "python3.8"
}

# ------------------ Start of IAM ------------------
resource "aws_iam_role" "lambda_iam_role" {
  name = "${local.prefix}lambda_iam_role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

# ------------------ End of IAM ------------------



# ------------------ Start of Lambdas ------------------
resource "aws_lambda_function" "process_data" {
  function_name = "${local.prefix}process_data"
  handler = "lambdas.process_data.lambda_handler"
  role = aws_iam_role.lambda_iam_role.arn
  runtime = local.python_version
}

resource "aws_lambda_function" "egress_data" {
  function_name = "${local.prefix}egress_data"
  handler = "lambdas.process_data.lambda_handler"
  role = aws_iam_role.lambda_iam_role.arn
  runtime = local.python_version
}
# ------------------ End of Lambdas ------------------