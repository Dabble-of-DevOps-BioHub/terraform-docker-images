FROM python:slim

# This image is just to get the various cli tools I need for the aws eks service

USER root
ARG TERRAFORM_VERSION="0.14.0"
ARG KUBECTL_VERSION="1.21.2"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y; apt-get upgrade -y; \
    apt-get install -y golang-go curl wget vim-tiny vim-athena jq unzip git build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

ENV PATH=/root/bin:/usr/local/bin:$PATH

RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

RUN curl -Lo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.16.0/terraform-docs-v0.16.0-$(uname)-amd64.tar.gz && \
	tar -xzf terraform-docs.tar.gz && \
	chmod +x terraform-docs && \
	mv terraform-docs /usr/local/terraform-docs

RUN git clone https://github.com/bats-core/bats-core.git && \
	 cd bats-core ; ./install.sh /usr/local

RUN echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
RUN echo 'alias l="ls -lah"' >> ~/.bashrc

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip

RUN pip install --upgrade ipython troposphere boto3 paramiko Jinja2 cookiecutter hiyapyco \
	jupyter-book sphinx pytest pandas s3fs livereload

# Install clis needed for kubernetes + eks

# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
RUN curl -o aws-iam-authenticator \
    https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x ./aws-iam-authenticator && \
    mkdir -p ~/bin && cp ./aws-iam-authenticator ~/bin/aws-iam-authenticator

RUN curl -LO https://dl.k8s.io/release/v1.21.0/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl ~/bin/kubectl && \
    kubectl version --client

WORKDIR /tmp

## Helm V3

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
    && chmod 700 get_helm.sh \
    && ./get_helm.sh

## EKSCTL

RUN curl -L -o eksctl.tar.gz \
    "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz"  \
    && tar -xvf eksctl.tar.gz \
    && chmod 777 eksctl \
    && mv eksctl /usr/local/bin \
    && eksctl version

## Terraform

RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && chmod 777 terraform \
    && mv terraform /usr/local/bin \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

WORKDIR /root
