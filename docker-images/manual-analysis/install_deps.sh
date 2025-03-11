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
    locales \
    zip --no-install-recommends


export LC_ALL=en_US.UTF-8 
export PYTHONIOENCODING=UTF-8

localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
locale-gen "en_US.UTF-8"


git clone https://github.com/pwndbg/pwndbg.git /src/pwdbg
pushd /src/pwdbg

git checkout tags/2022.08.30
./setup.sh

popd

export PATH=$IN:$PATH