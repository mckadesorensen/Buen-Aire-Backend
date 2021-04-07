variable "DEPLOY_NAME" {
  type = string
}

variable "AWS_ID_LAST_FOUR" {
  type = string
}

variable "DIST_DIR" {
  type = string
}

variable "REGION" {
  type = string
  default = "us-west-2"
}

variable "ACCOUNT" {
  type = string
}