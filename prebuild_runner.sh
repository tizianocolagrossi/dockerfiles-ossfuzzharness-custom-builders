#! /bin/bash

SSH_CREDS=$HOME/.ssh/id_ed25519

docker build -t osvaldo/oss-base-image  ./base-image
docker build -t osvaldo/oss-base-clang  ./base-clang
docker build -t osvaldo/oss-base-runner ./base-runner
