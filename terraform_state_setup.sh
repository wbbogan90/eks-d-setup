#!/bin/bash

# Create bucket and dynamo db table for terraform backend
aws s3api create-bucket \
    --bucket $S3_BUCKET \
    --acl private \
    --region $AWS_REGION \
    --create-bucket-configuration LocationConstraint=$AWS_REGION 2> /dev/null
aws s3api put-bucket-encryption --bucket $S3_BUCKET --server-side-encryption-configuration '{
    "Rules": [
        {
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }
    ]
}'
aws s3api put-public-access-block \
    --bucket $S3_BUCKET \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
aws s3api put-bucket-versioning --bucket $S3_BUCKET --versioning-configuration Status=Enabled
aws dynamodb create-table \
    --table-name $DYNAMO_TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 2> /dev/null