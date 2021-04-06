terraform {
  backend "s3" {}
}

provider "aws" {}

locals {
  prefix = "${var.DEPLOY_NAME}-buen-aire-"
  python_version = "python3.7"
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

resource "aws_iam_policy" "lambda-policy" {
  name = "${local.prefix}lambda-policy"
  policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Action": [
      "logs:*"
        ],
    "Resource": "arn:aws:logs:*:*:*"
  },
  {
    "Effect": "Allow",
    "Action": [
      "s3:*"
    ],
    "Resource": "arn:aws:s3:::*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda-policy-attach" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.lambda-policy.arn
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
resource "aws_lambda_layer_version" "lambda_dependencies" {
  filename =   "${var.DIST_DIR}/lambda_dependencies_layer.zip"
  layer_name = "${local.prefix}lambda_dependencies"

  compatible_runtimes = [
    local.python_version
  ]
}

resource "aws_lambda_function" "process_data" {
  filename = "${var.DIST_DIR}/process_lambda.zip"
  function_name = "${local.prefix}process_data"
  handler = "process_data.lambda_handler"
  role = aws_iam_role.lambda_iam_role.arn
  runtime = local.python_version
  layers = [aws_lambda_layer_version.lambda_dependencies.arn]

  memory_size = 512
  timeout = 60

  environment {
    variables = {
      S3_DATA_BUCKET = aws_s3_bucket.data-storage-bucket.bucket
    }
  }
}

resource "aws_lambda_function" "egress_data" {
  filename = "${var.DIST_DIR}/egress_lambda.zip"
  function_name = "${local.prefix}egress_data"
  handler = "egress_data.lambda_handler"
  role = aws_iam_role.lambda_iam_role.arn
  runtime = local.python_version
  layers = [aws_lambda_layer_version.lambda_dependencies.arn]

  timeout = 10

  environment {
    variables = {
      S3_DATA_BUCKET = aws_s3_bucket.data-storage-bucket.bucket
      BUCKET_REGION = aws_s3_bucket.data-storage-bucket.region
    }
  }
}
# ------------------ End of Lambdas ------------------

# ------------------ Start of API Gateway ------------------
# TODO: Make this do something
resource "aws_api_gateway_rest_api" "api" {
  name = "${local.prefix}api-gateway"
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
  uri = aws_lambda_function.egress_data.invoke_arn
}

resource "aws_lambda_permission" "api_permissions" {
  statement_id  = "AllowAPIgatewayInvokation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.egress_data.function_name
  principal     = "apigateway.amazonaws.com"
}
# ------------------ End of API Gateway ------------------