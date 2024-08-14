#! /bin/bash

if [ -z "$1" ]
  then
    echo "Version of enumetric to build required"
    echo "Example: $0 v0.2.4"
    exit 0
fi

SSH_CREDS=$HOME/.ssh/id_ed25519

docker build -t osvaldo/oss-base-image  ./base-image
docker build -t osvaldo/oss-base-clang  ./base-clang
docker build -t osvaldo/oss-base-runner ./base-runner

# docker build -t oss-base-analysis ./base-analysis
DOCKER_BUILDKIT=1 docker build \
    -t osvaldo/oss-base-analysis \
    --ssh default=$SSH_CREDS \
    ./base-analysis

# DOCKER_BUILDKIT=1 docker build \
#     --build-arg UID=$(id -u) --build-arg GID=$(id -g) \
#     -t oss-base-analysis-crash \
#     --ssh default=$SSH_CREDS \
#     ./base-analysis-crash
# docker build -t enumetric-analysis:$1 ./analysis-libafl-enumetric

DOCKER_BUILDKIT=1 docker build \
    --build-arg enumetricversion=$1 \
    -t osvaldo/base-builder:$1 \
    --ssh default=$SSH_CREDS \
    ./base-builder
