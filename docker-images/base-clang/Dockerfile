# Copyright 2016 Google Inc.
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

# Docker image with head clang installed.

FROM osvaldo/oss-base-image

ARG arch=x86_64

ENV FUZZINTRO_OUTDIR=$SRC


# Install newer cmake.
ENV CMAKE_VERSION=3.24.2
RUN apt-get update && apt-get install -y wget sudo && \
    wget -q https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-Linux-$arch.sh && \
    chmod +x cmake-$CMAKE_VERSION-Linux-$arch.sh && \
    ./cmake-$CMAKE_VERSION-Linux-$arch.sh --skip-license --prefix="/usr/local" && \
    rm cmake-$CMAKE_VERSION-Linux-$arch.sh && \
    SUDO_FORCE_REMOVE=yes apt-get autoremove --purge -y wget sudo && \
    rm -rf /usr/local/doc/cmake /usr/local/bin/cmake-gui

COPY checkout_build_install_llvm_rust.sh /root/
# Keep all steps in the same script to decrease the number of intermediate
# layes in docker file.
RUN /root/checkout_build_install_llvm_rust.sh
RUN rm /root/checkout_build_install_llvm_rust.sh

COPY create_dummy_libFuzzingEngine /root/
RUN /root/create_dummy_libFuzzingEngine
RUN rm /root/create_dummy_libFuzzingEngine

RUN git clone https://github.com/zyingp/desockmulti.git /$SRC/desockmulti && cd /$SRC/desockmulti && make 

# Setup the environment.
ENV CC="clang-13"
ENV CXX="clang++-13"
ENV CCC="clang++-13"

ENV CFLAGS="-O1 -fno-omit-frame-pointer -gline-tables-only -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
#"-stdlib=libc++"
ENV CXXFLAGS_EXTRA="" 
ENV CXXFLAGS="$CFLAGS $CXXFLAGS_EXTRA"
