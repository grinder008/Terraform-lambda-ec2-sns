import json
import os
import boto3 # type: ignore

sns = boto3.client("sns")

TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

def handler(event, context):

    detail = event.get("detail", {})

    user_arn = detail.get("userIdentity", {}).get("arn", "Unknown")

    instance_id = "Unknown"

    instances = (
        detail.get("responseElements", {})
        .get("instancesSet", {})
        .get("items", [])
    )

    if instances:
        instance_id = instances[0].get("instanceId", "Unknown")

    region = event.get("region", "Unknown")

    message = f"""
EC2 Instance Created bitch ass nigga!

User:
{user_arn}

Instance ID:
{instance_id}

Region:
{region}
"""

    sns.publish(
        TopicArn=TOPIC_ARN,
        Subject="[ALERT] EC2 Created",
        Message=message
    )

    return {
        "statusCode": 200
    }