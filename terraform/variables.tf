terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.45.0"
    }
  }
}

# Specified by environment variable TF_VAR_AWS_REGION
variable "AWS_REGION" {
    type        = string
    description = "The name of the AWS region in which to provision the EKS cluster."
}

# Specified by environment variable TF_VAR_S3_BUCKET
variable "S3_BUCKET" {
    type        = string
    description = "The name of the S3 bucket used for the Terraform backend."
}

# Specified by environment variable TF_VAR_DYNAMO_TABLE
variable "DYNAMO_TABLE" {
    type        = string
    description = "The name of the Dynamo table used for the Terraform backend."
}

# Specified by environment variable TF_VAR_AWS_PROFILE
variable "AWS_PROFILE" {
    type        = string
    description = "The name of the AWS profile to use from the mounted ~/.aws/credentials file."
}