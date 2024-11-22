"""
This script captures, then sets KMS variables
KMS Key alias is created and pointed to new key.
KMS Key Rotation is enabled.
"""

import json
import logging
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s: %(levelname)s: %(message)s"
)


def lambda_handler(event, context):
    """
    KMS Key Generate function
    """
    try:
        """
        Creates a unique customer managed KMS key.
        """
        kms_client = boto3.client("kms")
        response = kms_client.create_key(
            Description=event["KeyDescription"], KeyUsage=event["KeyUsage"]
        )
        print(response)

        """
        Creates alias and associate with new KMS key.
        """
        key_id = response["KeyMetadata"]["Arn"]
        response = kms_client.create_alias(
            AliasName=event["KeyAlias"], TargetKeyId=key_id
        )

        """
        Create and set KMS Key Policy.
        """
        account = event["Account"]
        policy_name = "default"
        policy = {
            "Version": "2012-10-17",
            "Id": "kms-key-policy",
            "Statement": [
                {
                    "Sid": "KMS Key IAM Permissions",
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": [
                            "arn:aws:iam::012345678910:root",
                            "arn:aws:iam::" + account + ":root",
                        ]
                    },
                    "Action": "kms:*",
                    "Resource": "*",
                }
            ],
        }
        response = kms_client.put_key_policy(
            KeyId=key_id, Policy=json.dumps(policy), PolicyName=policy_name
        )

        """
        Enable KMS Key Rotation.
        """
        response = kms_client.enable_key_rotation(KeyId=key_id)

    except ClientError as err:
        logging.error(
            "Couldn't create your key. Reason: %s",
            err.response["Error"]["Message"],
        )
        raise


if __name__ == "__main__":
    logger.info("Creating KMS Key")
