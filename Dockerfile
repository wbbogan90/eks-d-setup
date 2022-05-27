FROM centos:centos7

ARG BUCKET=deo-eks-d-tf
ARG TABLE=deo-eks-d-state-locking
ARG PROFILE=deo
ARG USERNAME=ec2-user
# Override the following with the docker exec command as needed using --build-arg
ARG REGION=us-east-2
ARG KMS_ARN=arn:aws:kms:us-east-2:691666183092:key/93238f20-5758-4198-a657-538b5f56ef9b
ARG AWS_CLI_URL=https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
ARG TERRAFORM_URL=https://releases.hashicorp.com/terraform/1.2.1/terraform_1.2.1_linux_amd64.zip
ARG KUBEONE_URL=https://github.com/kubermatic/kubeone/releases/download/v1.4.3/kubeone_1.4.3_linux_amd64.zip

# Update the package repositories and default certs for CentOS as required

# Install needed binaries
RUN yum install -y which wget curl unzip python3

# Make eks user, copy setup scripts
RUN useradd -ms /bin/bash -u 1000 $USERNAME && \
    mkdir -p /home/$USERNAME/python && \
    mkdir -p /home/$USERNAME/terraform
COPY python/environment.yml /home/$USERNAME/python/.
COPY python/setup.py /home/$USERNAME/python/.
COPY terraform/*.tf /home/$USERNAME/terraform/
COPY setup.sh /home/$USERNAME/.
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME && \
    chmod +x /home/$USERNAME/setup.sh

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
ENV KMS_KEY_ARN=$KMS_ARN
ENV TF_VAR_S3_BUCKET=$BUCKET
ENV TF_VAR_AWS_PROFILE=$PROFILE
ENV TF_VAR_DYNAMO_TABLE=$TABLE
ENV TF_VAR_AWS_REGION=$REGION

USER $USERNAME
WORKDIR /home/$USERNAME

RUN mkdir -p /home/$USERNAME/miniconda3 \
    && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /home/$USERNAME/miniconda3/miniconda.sh \
    && bash /home/$USERNAME/miniconda3/miniconda.sh -b -u -p /home/$USERNAME/miniconda3 \
    && rm -rf /home/$USERNAME/miniconda3/miniconda.sh \
    && /home/$USERNAME/miniconda3/bin/conda init bash \
    && /home/$USERNAME/miniconda3/bin/conda env create -f /home/$USERNAME/python/environment.yml \
    && mkdir -p /home/$USERNAME/.ssh

ENTRYPOINT ["/bin/bash"]