#!/bin/bash

$HOME/miniconda3/bin/conda run -n eks-d python python/setup.py $TF_VAR_AWS_REGION $KMS_KEY_ARN
cd terraform
terraform init