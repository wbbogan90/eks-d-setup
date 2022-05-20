provider "aws" {
    region = "us-east-2"
    profile = "deo"
}

terraform {
    backend "s3" {
        bucket = "deo-eks-d-tf"
        key = "terraform.tfstate"
        region = "us-east-2"
        dynamodb_table = "deo-eks-d-state-locking"
    }
}