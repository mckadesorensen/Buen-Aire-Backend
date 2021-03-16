#!/bin/bash

if (( $# != 2 )); then
    echo "Command structure: source env.sh aws_profile_name deploy_name"
else
    export AWS_PROFILE=$1

    AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile "$AWS_PROFILE")
    AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile "$AWS_PROFILE")
    AWS_REGION=$(aws configure get region --profile "$AWS_PROFILE" || echo $AWS_DEFAULT_REGION)

    export AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY
    export AWS_REGION
    export DEPLOY_NAME=$2

    echo " environment vars:"
    echo "  AWS_PROFILE:          $AWS_PROFILE"
    echo "  AWS_REGION:           $AWS_REGION"
    echo "  DEPLOY_NAME:          $DEPLOY_NAME"
fi
