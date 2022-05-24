FROM centos:centos7

ARG BUCKET=deo-eks-d-tf
ARG TABLE=deo-eks-d-state-locking
ARG REGION=us-east-2
ARG PROFILE=deo
ARG AWS_CLI_URL=https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
ARG TERRAFORM_URL=https://releases.hashicorp.com/terraform/1.2.1/terraform_1.2.1_linux_amd64.zip
ARG KUBEONE_URL=https://github.com/kubermatic/kubeone/releases/download/v1.4.3/kubeone_1.4.3_linux_amd64.zip

# Install needed binaries
RUN yum install -y curl unzip

# Make eks user, copy AWS credentials
RUN useradd -ms /bin/bash -u 1000 eks && mkdir -p /home/eks/.aws
COPY credentials /home/eks/.aws/.
RUN chown -R eks:eks /home/eks/.aws && chmod 600 /home/eks/.aws/credentials

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
ENV DYNAMO_TABLE=$TABLE
ENV AWS_REGION=$REGION
USER eks
WORKDIR /home/eks

ENTRYPOINT ["/bin/bash"]