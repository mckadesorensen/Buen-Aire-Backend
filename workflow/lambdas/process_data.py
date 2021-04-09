import os
import logging
from json import dumps, loads

import boto3
from purpleair.network import SensorList

s3 = boto3.resource("s3")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


# --------------- Start of s3 formatting functions ---------------
def grab_ak_data(purple_air_data):
    ak_data = []
    for info in purple_air_data:
        try:
            if 52 <= info['lat'] <= 75 and -175 <= info['lon'] <= -128:
                ak_data.append(info)
        except TypeError as e:
            logger.info(f"The falling data: {info}, gave the following error {e}")

    return ak_data


# TODO: Get with team and figure out how we want to properly format this data
def format_data(purple_air):
    return dumps({
        "PurpleAir": purple_air
    })
# --------------- End of s3 formatting functions ---------------


# --------------- Start of s3 functions ---------------
def set_file_public_read_access(bucket, file_name):
    object_acl = s3.ObjectAcl(bucket, file_name)
    response = object_acl.put(ACL='public-read')
    logger.info(f"Response: {response}")


# TODO: Set up file name
def store_file_in_s3(data):
    bucket = os.getenv("S3_DATA_BUCKET")
    file_name = "test.json"

    logger.info(f"Storing {file_name} in {bucket}")
    s3.Bucket(bucket).put_object(Key=file_name, Body=data)
    set_file_public_read_access(bucket, file_name)
# --------------- Start of s3 functions ---------------


# --------------- Start of gathering data functions ---------------
def get_data_from_purple_air():
    p = SensorList()
    df = p.to_dataframe(sensor_filter='all', channel='parent')
    return df.to_json(orient="records")


def pull_data_from_all_sources():
    purple_air_data = loads(get_data_from_purple_air())
    ak_purple_air_data = grab_ak_data(purple_air_data)
    logger.info(f"Pulled the following data from purple air: {ak_purple_air_data}")
    encoded_data = format_data(ak_purple_air_data).encode("utf-8")
    store_file_in_s3(encoded_data)
# --------------- End of gathering data functions ---------------


def lambda_handler(event, context):
    logger.info(f"Event: {event}")
    logger.info(f"Context: {context}")
    pull_data_from_all_sources()
