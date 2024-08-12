#! /bin/bash

if [ -z "$1" ]
  then
    echo "Version of enumetric to build required"
    echo "Example: $0 v0.2.4"
    exit 0
fi


docker build -t oss-base-image  ./base-image
docker build -t oss-base-clang  ./base-clang
docker build -t oss-base-runner ./base-runner

# docker build -t oss-base-analysis ./base-analysis
DOCKER_BUILDKIT=1 docker build \
    -t oss-base-analysis \
    --ssh default=$HOME/.ssh/id_ed25519 \
    ./base-analysis

# DOCKER_BUILDKIT=1 docker build \
#     --build-arg UID=$(id -u) --build-arg GID=$(id -g) \
#     -t oss-base-analysis-crash \
#     --ssh default=$HOME/.ssh/id_ed25519 \
#     ./base-analysis-crash
# docker build -t enumetric-analysis:$1 ./analysis-libafl-enumetric

DOCKER_BUILDKIT=1 docker build \
    --build-arg enumetricversion=$1 \
    -t base-builder:$1 \
    --ssh default=$HOME/.ssh/id_ed25519 \
    ./base-builder
