#! /bin/bash

if [ -z "$1" ]
  then
    echo "Version of enumetric to build required"
    echo "Example: ./$0 v0.2.4"
    exit 0
fi


docker build -t oss-base-image  ./base-image
docker build -t oss-base-clang  ./base-clang
docker build -t oss-base-runner ./base-runner
docker build -t enumetric-analysis:$1 ./analysis-libafl-enumetric

DOCKER_BUILDKIT=1 docker build \
    --build-arg enumetric-version=$1 \
    -t builder-libafl-baseline:$1 \
    --ssh default=$HOME/.ssh/id_ed25519 \
    ./builder-libafl-baseline

DOCKER_BUILDKIT=1 docker build \
    --build-arg enumetric-version=$1 \
    -t builder-libafl-enumetric:$1 \
    --ssh default=$HOME/.ssh/id_ed25519 \
    ./builder-libafl-enumetric

DOCKER_BUILDKIT=1 docker build \
    --build-arg enumetric-version=$1 \
    -t builder-libafl-enumetric_mm:$1 \
    --ssh default=$HOME/.ssh/id_ed25519 \
    ./builder-libafl-enumetricMM
