#! /bin/bash

docker build -t oss/base-image ./base-image
docker build -t oss/base-clang ./base-clang

DOCKER_BUILDKIT=1 docker build -t builder/libafl-baseline --ssh default=$HOME/.ssh/id_ed25519 ./builder-libafl-baseline
DOCKER_BUILDKIT=1 docker build -t builder/libafl-enumetric --ssh default=$HOME/.ssh/id_ed25519 ./builder-libafl-enumetric
DOCKER_BUILDKIT=1 docker build -t builder/libafl-enumetricMM --ssh default=$HOME/.ssh/id_ed25519 ./builder-libafl-enumetricMM
