provider "aws" {
    region = var.AWS_REGION
    profile = var.AWS_PROFILE
}

terraform {
    backend "s3" {
        bucket = "sample-bucket"
        key = "terraform.tfstate"
        region = "sample-region"
        dynamodb_table = "sample-table"
    }
}