import boto3
import os


# TODO: Set up with API Gateway
def create_recent_data_url():
    bucket, region = os.getenv("S3_DATA_BUCKET"), os.getenv("BUCKET_REGION")
    s3_client = boto3.client('s3')
    files = s3_client.list_objects_v2(Bucket=bucket)["Contents"]

    # TODO: Put the correct file name in place
    url = f"https://{bucket}.s3-{region}.amazonaws.com/{files[0]['Key']}"
    print(url)


def lambda_handler(event, context):
    create_recent_data_url()
