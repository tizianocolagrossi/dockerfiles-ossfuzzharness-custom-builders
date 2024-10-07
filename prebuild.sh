#! /bin/bash

if [ -z "$1" ]
  then
    echo "Version of enumetric to build required"
    echo "Example: $0 v0.2.6tmp6-aflpp-doublem"
    exit 0
fi

SSH_CREDS=$HOME/.ssh/id_ed25519

docker build -t osvaldo/oss-base-image  ./docker-images/base-image
docker build -t osvaldo/oss-base-clang  ./docker-images/base-clang
docker build -t osvaldo/oss-base-runner ./docker-images/base-runner

# docker build -t oss-base-analysis ./base-analysis
DOCKER_BUILDKIT=1 docker build \
    -t osvaldo/oss-base-analysis \
    --ssh default=$SSH_CREDS \
    ./docker-images/base-analysis

DOCKER_BUILDKIT=1 docker build \
    --build-arg enumetricversion=$1 \
    -t osvaldo/base-builder:$1 \
    --ssh default=$SSH_CREDS \
    ./docker-images/base-builder
