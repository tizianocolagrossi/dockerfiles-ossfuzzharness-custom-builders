#! /bin/bash

apt-get update && apt-get install -y \
    binutils \
    file \
    fonts-dejavu \
    git \
    python3 \
    python3-pip \
    python3-setuptools \
    unzip \
    wget \
    zip --no-install-recommends

git clone https://github.com/pwndbg/pwndbg.git /src/pwdbg
pushd /src/pwdbg

git checkout tags/2024.08.29
./setup.sh

popd

export PATH=$IN:$PATH