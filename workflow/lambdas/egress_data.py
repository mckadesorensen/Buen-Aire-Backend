import boto3
import os
import json


def create_recent_data_url():
    bucket, region = os.getenv("S3_DATA_BUCKET"), os.getenv("BUCKET_REGION")
    s3_client = boto3.client('s3')
    files = s3_client.list_objects_v2(Bucket=bucket)["Contents"]
    print(files)

    for file in files:
        data = s3_client.get_object(Bucket=bucket, Key=file.get('Key'))
        contents = data['Body'].read()

    return contents.decode('UTF-8')


def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "body": create_recent_data_url()
    }