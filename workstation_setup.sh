#!/bin/bash

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