# TODO: Finish Process data lambda
from json import dumps
import os

import boto3
from purpleair.network import SensorList


s3 = boto3.resource("s3")


# --------------- Start of s3 formatting functions ---------------
# TODO: Get with team and figure out how we want to properly format this data
def format_data(purple_air):
    return dumps({
        "PurpleAir": purple_air
    })
# --------------- End of s3 formatting functions ---------------


# --------------- Start of s3 functions ---------------
# TODO: Add logging and log response
def set_file_public_read_access(bucket, file_name):
    object_acl = s3.ObjectAcl(bucket, file_name)
    response = object_acl.put(ACL='public-read')


# TODO: Set up file name
def store_file_in_s3(data):
    bucket = os.getenv("S3_DATA_BUCKET")
    file_name = "test.json"

    s3.Bucket(bucket).put_object(Key=file_name, Body=data)
    set_file_public_read_access(bucket, file_name)
# --------------- Start of s3 functions ---------------


# --------------- Start of gathering data functions ---------------
def get_data_from_purple_air():
    p = SensorList()
    df = p.to_dataframe(sensor_filter='all', channel='parent')
    return df.to_json(orient="records")


def pull_data_from_all_sources():
    purple_air_data = get_data_from_purple_air()
    encoded_data = format_data(purple_air_data).encode("utf-8")
    store_file_in_s3(encoded_data)
# --------------- End of gathering data functions ---------------


def lambda_handler(event, context):
    pull_data_from_all_sources()
