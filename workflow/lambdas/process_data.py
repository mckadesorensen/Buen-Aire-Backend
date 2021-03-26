# TODO: Finish Process data lambda
from json import dumps
import os

import boto3
from purpleair.network import SensorList


def format_data(purple_air, uaf_smoke):
    return dumps({
        "PurpleAir": purple_air,
        "UAFSmoke": uaf_smoke
    })


def store_in_s3():
    purple_air_data = get_data_from_purple_air()
    uaf_smoke_data = "TODO"
    data = format_data(purple_air_data, uaf_smoke_data)
    encoded_data = data.encode("utf-8")
    bucket = os.getenv("S3_DATA_BUCKET")
    file_name = "test.json"

    s3 = boto3.resource("s3")
    s3.Bucket(bucket).put_object(Key=file_name, Body=encoded_data)


def get_data_from_purple_air():
    p = SensorList()
    df = p.to_dataframe(sensor_filter='all',
                        channel='parent')
    return df.to_json(orient="records")


def lambda_handler(event, context):
    store_in_s3()