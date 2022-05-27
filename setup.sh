#!/bin/bash

$HOME/miniconda3/bin/conda run -n eks-d python python/setup.py $AWS_REGION $KMS_KEY_ARN