#! /bin/bash


SSH_CREDS=$HOME/.ssh/id_ed25519

docker build -t osvaldo/oss-base-image     ./docker-images/base-image
docker build -t osvaldo/oss-base-clang     ./docker-images/base-clang
docker build -t osvaldo/oss-base-clang-10  ./docker-images/base-clang-10
docker build -t osvaldo/oss-base-runner    ./docker-images/base-runner
docker build -t osvaldo/manual-analysis    ./docker-images/manual-analysis/

# docker build -t oss-base-analysis ./base-analysis
DOCKER_BUILDKIT=1 docker build \
    -t osvaldo/oss-base-analysis \
    --ssh default=$SSH_CREDS \
    ./docker-images/base-analysis

DOCKER_BUILDKIT=1 docker build \
    -t osvaldo/base-builder \
    --ssh default=$SSH_CREDS \
    ./docker-images/base-builder

docker build -t osvaldo/sgfuzzer-builder ./docker-images/sgfuzzer-builder
