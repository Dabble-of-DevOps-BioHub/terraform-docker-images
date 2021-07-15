#FROM continuumio/miniconda3:latest
FROM python:slim

# This image is just to get the various cli tools I need for the aws eks service
# AWS CLI - Whatever the latest version is
# AWS IAM Authenticator - 1.12.7
# Kubectl - 1.12.7

USER root
ARG TERRAFORM_VERSION="0.14.0"
# ARG TERRAFORM_VERSION="0.12.28"
# ARG AWS_IAM_AUTHENTICATION_VERSION="1.12.7"
ARG KUBECTL_VERSION="1.21.2"

RUN apt-get update -y; apt-get upgrade -y; \
    apt-get install -y curl wget vim-tiny vim-athena jq unzip git

WORKDIR /tmp

ENV PATH=/root/bin:$PATH
RUN echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
RUN echo 'alias l="ls -lah"' >> ~/.bashrc

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

RUN pip install --upgrade ipython troposphere boto3 paramiko

# Install clis needed for kubernetes + eks

# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
RUN curl -o aws-iam-authenticator \
    https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x ./aws-iam-authenticator

RUN mkdir -p ~/bin && cp ./aws-iam-authenticator ~/bin/aws-iam-authenticator

RUN    curl -LO https://dl.k8s.io/release/v1.21.0/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl ~/bin/kubectl && \
    kubectl version --client

WORKDIR /tmp

## Helm V3

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
    && chmod 700 get_helm.sh \
    && ./get_helm.sh

## EKSCTL

RUN curl --silent --location \
    "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp \
    mv /tmp/eksctl /usr/local/bin && \
    eksctl version

## Terraform

RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

WORKDIR /root

