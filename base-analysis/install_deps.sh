#!/bin/bash 
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

# Install dependencies in a platform-aware way.

apt-get update && apt-get install -y \
    binutils \
    file \
    fonts-dejavu \
    git \
    libcap2 \
    python3 \
    python3-pip \
    python3-setuptools \
    rsync \
    unzip \
    wget \
    curl \
    build-essential \
    make \
    gdb \
    libinih-dev \
    zip --no-install-recommends

apt install -y gnupg lsb-release software-properties-common build-essential --no-install-recommends


case $(uname -m) in
  x86_64)
    # We only need to worry about i386 if we are on x86_64.
    apt-get install -y lib32gcc1 libc6-i386
    ;;
esac

#get llvm
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
./llvm.sh 13
rm -f llvm.sh

# Get Rust
curl https://sh.rustup.rs -sSf | bash -s -- -y
echo 'source $HOME/.cargo/env' >> $HOME/.bashrc
source $HOME/.cargo/env

# git clone https://github.com/quic/AFLTriage.git $SRC/AFLTriage
pushd $SRC/BAAFLTriage
cargo build --release
ln -s $SRC/BAAFLTriage/target/release/baafltriage /usr/local/bin/afltriage
popd
