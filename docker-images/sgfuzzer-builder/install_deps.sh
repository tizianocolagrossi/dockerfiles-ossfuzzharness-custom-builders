#!/bin/bash -eux
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

# Install base-builder's dependencies in a architecture-aware way.


case $(uname -m) in
    x86_64)
	dpkg --add-architecture i386
        ;;
esac

apt-get update && \
    apt-get install -y \
        binutils-dev \
        build-essential \
        llvm-10-dev \
        curl \
        wget \
        git \
        jq \
        patchelf \
        rsync \
        subversion \
        python3-dev \
        automake \
        cmake \
        automake \
        flex \
        bison \
        libglib2.0-dev \
        libpixman-1-dev \
        python3-setuptools \
        cargo \
        libgtk-3-dev \
        zip

case $(uname -m) in
    x86_64)
	apt-get install -y libc6-dev-i386
        ;;
esac