FROM continuumio/miniconda3:4.10.3-alpine

# BioAnalyze uses jupyter-book and other python tools
# Want to make terraform/python consistent

LABEL "com.github.actions.name"="Build Harness"
LABEL "com.github.actions.description"="Run any build-harness make target"
LABEL "com.github.actions.icon"="tool"
LABEL "com.github.actions.color"="blue"

COPY --from=golang:1.15.11-alpine3.13 /usr/local/go/ /usr/local/go/
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"
ENV HOME="/root"
ENV GOLANG_VERSION=1.13.15

WORKDIR /tmp
RUN rm /usr/glibc-compat/lib/ld-linux-x86-64.so.2 && /usr/glibc-compat/sbin/ldconfig
    #   libc6-compat \
RUN apk --update --no-cache add \
      bash \
      ca-certificates \
      coreutils \
      curl \
      git \
      gettext \
      go \
      grep \
      groff \
      jq \
      make \
      perl

COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --upgrade pip setuptools wheel && \
    pip3 install --no-cache-dir \
      PyYAML==5.4.1 \
      awscli==1.20.28 \
      boto==2.49.0 \
      boto3==1.18.28 \
      iteration-utilities==0.11.0 \
      pre-commit \
      PyGithub==1.54.1 && \
    pip3 install --no-cache-dir -r /tmp/requirements.txt
RUN git config --global advice.detachedHead false

# install awscliv2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# Install kubectl
RUN curl -LO \
    "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# Install aws iam authenticator
RUN curl -o aws-iam-authenticator \
    https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x ./aws-iam-authenticator && \
    mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -fsSL --retry 3 https://apk.cloudposse.com/install.sh | bash

## Install as packages

## Codefresh required additional libraries for alpine
## So can not be curl binary
RUN apk --update --no-cache add \
      chamber@cloudposse \
      gomplate@cloudposse \
      helm@cloudposse \
      helmfile@cloudposse \
      codefresh@cloudposse \
      terraform-0.11@cloudposse terraform-0.12@cloudposse \
      terraform-0.13@cloudposse terraform-0.14@cloudposse \
      terraform-0.15@cloudposse terraform-1@cloudposse \
      terraform-config-inspect@cloudposse \
      terraform-docs@cloudposse \
      vert@cloudposse \
      yq@cloudposse && \
    sed -i /PATH=/d /etc/profile


# Patch for old Makefiles that expect a directory like x.x from the 0.x days.
# Fortunately, they only look for the current version, so we only need links
# for the current major version.
RUN v=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version' | cut -d. -f1-2) && \
    major=${v%%\.*} && n=$(( ${v##*\.} + 1 )) && \
    for (( x=0; x <= $n; x++ )); do ln -s /usr/local/terraform/{${major},${major}.${x}}; done

ENV INSTALL_PATH /usr/local/bin

WORKDIR /
RUN wget -O Makefile https://raw.githubusercontent.com/cloudposse/build-harness/master/templates/Makefile.build-harness
RUN make init
WORKDIR /build-harness

ARG PACKAGES_PREFER_HOST=true
RUN make -s bash/lint make/lint
RUN make -s template/deps readme/deps
RUN make -s go/deps-build go/deps-dev

# Use Terraform 1 by default
ARG DEFAULT_TERRAFORM_VERSION=1
RUN update-alternatives --set terraform /usr/share/terraform/$DEFAULT_TERRAFORM_VERSION/bin/terraform && \
  mkdir -p /build-harness/vendor && \
  cp -p /usr/share/terraform/$DEFAULT_TERRAFORM_VERSION/bin/terraform /build-harness/vendor/terraform