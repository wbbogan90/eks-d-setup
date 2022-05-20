#!/bin/bash
export BUCKET_NAME=deo-eks-d-tf
export TABLE_NAME=deo-eks-d-state-locking
export AWS_REGION=us-east-2
export AWS_PROFILE=deo

# Update Ubuntu and install updated/necessary packages
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
sudo add-apt-repository ppa:git-core/ppa -y
sudo apt-get install git -y

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws
rm awscliv2.zip

# Install terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install KubeOne
sudo curl -sfL get.kubeone.io | sh

# Create bucket and dynamo db table for terraform backend
aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --acl private \
    --region $AWS_REGION \
    --create-bucket-configuration LocationConstraint=$AWS_REGION 2> /dev/null
aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{
    "Rules": [
        {
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }
    ]
}'
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 2> /dev/null