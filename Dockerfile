FROM centos:centos7

ARG BUCKET=deo-eks-d-tf
ARG TABLE=deo-eks-d-state-locking
ARG REGION=us-east-2
ARG PROFILE=deo
ARG KMS_ARN=arn:aws:kms:us-east-2:691666183092:key/93238f20-5758-4198-a657-538b5f56ef9b
ARG AWS_CLI_URL=https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
ARG TERRAFORM_URL=https://releases.hashicorp.com/terraform/1.2.1/terraform_1.2.1_linux_amd64.zip
ARG KUBEONE_URL=https://github.com/kubermatic/kubeone/releases/download/v1.4.3/kubeone_1.4.3_linux_amd64.zip

# Install needed binaries
RUN yum install -y which wget curl unzip python3

# Make eks user, copy setup scripts
RUN useradd -ms /bin/bash -u 1000 eks && mkdir -p /home/eks/python
COPY python/ /home/eks/python/
RUN chown -R eks:eks /home/eks

# Install AWS CLI
RUN curl $AWS_CLI_URL -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws \
    && rm awscliv2.zip

# Install Terraform CLI
RUN curl $TERRAFORM_URL -o "terraformCLI.zip" \
    && unzip terraformCLI.zip -d terraform-cli \
    && mv terraform-cli/terraform /usr/local/bin/ \
    && rm -rf terraform-cli

# Install KubeOne CLI
RUN curl -L $KUBEONE_URL -o "kubeoneCLI.zip" \
    && unzip kubeoneCLI.zip -d kubeone-cli \
    && mv kubeone-cli/kubeone /usr/local/bin/ \
    && rm -rf kubeone-cli

ENV AWS_PROFILE=$PROFILE
ENV S3_BUCKET=$BUCKET
ENV KMS_KEY_ARN=$KMS_ARN
ENV DYNAMO_TABLE=$TABLE
ENV AWS_REGION=$REGION

USER eks
WORKDIR /home/eks

RUN mkdir -p ~/miniconda3 \
    && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh \
    && bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 \
    && rm -rf ~/miniconda3/miniconda.sh \
    && ~/miniconda3/bin/conda init bash \
    && ~/miniconda3/bin/conda env create -f ~/python/environment.yml

ENTRYPOINT ["/bin/bash"]