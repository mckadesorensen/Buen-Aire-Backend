terraform {
  backend "s3" {}
}

provider "aws" {}

locals {
  prefix = "${var.DEPLOY_NAME}-buen-aire-"
  python_version = "python3.8"
  zipped_lambdas = "lambdas.zip"
  zipped_lambda_bucket = "s3://${var.DEPLOY_NAME}-buen-aire-lambda-code-${var.AWS_ID_LAST_FOUR}"
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

# ------------------ Start of S3 Bucket ------------------
resource "aws_s3_bucket" "data-storage-bucket" {
  bucket = "${local.prefix}data-storage-${var.AWS_ID_LAST_FOUR}"
  versioning {
    enabled = true
  }
  lifecycle {
    prevent_destroy = true
  }
}
# ------------------ End of S3 Bucket ------------------


# ------------------ Start of Lambdas ------------------
resource "aws_lambda_function" "process_data" {
  filename = "${var.DIST_DIR}/${local.zipped_lambdas}"
  function_name = "${local.prefix}process_data"
  handler = "workflow.lambdas.process_data.lambda_handler"
  role = aws_iam_role.lambda_iam_role.arn
  runtime = local.python_version
}

resource "aws_lambda_function" "egress_data" {
  filename = "${var.DIST_DIR}/${local.zipped_lambdas}"
  function_name = "${local.prefix}egress_data"
  handler = "workflow.lambdas.egress_data.lambda_handler"
  role = aws_iam_role.lambda_iam_role.arn
  runtime = local.python_version
}
# ------------------ End of Lambdas ------------------

# ------------------ Start of API Gateway ------------------
# TODO: Make this do something
resource "aws_api_gateway_rest_api" "api" {
  name = "${local.prefix}-api-gateway"
  description = "Proxy for handling request to the Buen Aire API"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}
resource "aws_api_gateway_integration" "integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  integration_http_method = "ANY"
  type = "HTTP_PROXY"
  uri = "http://your.domain.com/{proxy}"

  request_parameters =  {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# ------------------ End of API Gateway ------------------