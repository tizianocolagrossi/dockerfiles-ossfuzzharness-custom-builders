#! /bin/bash

SSH_CREDS=$HOME/.ssh/id_ed25519

docker build -t osvaldo/oss-base-image  ./docker-images/base-image
docker build -t osvaldo/oss-base-clang  ./docker-images/base-clang
docker build --no-cache -t osvaldo/oss-base-runner ./docker-images/base-runner
