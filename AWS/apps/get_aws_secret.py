#!/usr/bin/python3

import boto3
from botocore.exceptions import ClientError
import argparse

def get_secret(args):
    secret_name = args.secret_name
    region_name = args.region_name

    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name,
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            print("The requested secret " + secret_name + " was not found")
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            print("The request was invalid due to:", e)
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            print("The request had invalid params:", e)
        elif e.response['Error']['Code'] == 'DecryptionFailure':
            print("The requested secret can't be decrypted using the provided KMS key:", e)
        elif e.response['Error']['Code'] == 'InternalServiceError':
            print("An error occurred on service side:", e)
    else:
        # Secrets Manager decrypts the secret value using the associated KMS CMK
        # Depending on whether the secret was a string or binary, only one of these fields will be populated
        if 'SecretString' in get_secret_value_response:
            return get_secret_value_response['SecretString']
        else:
            return get_secret_value_response['SecretBinary']

        
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Retrieve a secret from AWS Secrets Manager")
    parser.add_argument("--secret-name", required=True, help="The name of the secret")
    parser.add_argument("--region-name", default="us-east-2", help="The AWS region (default: us-east-2)")
    args = parser.parse_args()
    print(get_secret(args))