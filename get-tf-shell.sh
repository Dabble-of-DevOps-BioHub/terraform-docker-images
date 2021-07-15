#!/usr/bin/env bash

NAME="k8-dev"

docker build -t ${NAME} .

# Terraform no longer works as is using volume binds
# I think it happened with a docker update
docker run -it \
	-v "$(pwd)/.aws:/root/.aws:Z" \
	-v "$(pwd)/.kube:/root/.kube:Z" \
    -v "$(pwd):/root/project:Z" \
	${NAME} bash

