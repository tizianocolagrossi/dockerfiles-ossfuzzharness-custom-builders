# Copyright 2021 Google LLC
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

FROM osvaldo/oss-base-clang

COPY install_deps.sh /
RUN /install_deps.sh && rm /install_deps.sh

ARG enumetricversion=v0.2.4

RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

RUN ln -s /usr/bin/llvm-profdata-13 /usr/bin/llvm-profdata

# DEPRECATED - NEW CODE SHOULD NOT USE THIS. OLD CODE SHOULD STOP. Please use
# LIB_FUZZING_ENGINE instead.
# Path to fuzzing engine library to support some old users of
# LIB_FUZZING_ENGINE.
ENV LIB_FUZZING_ENGINE_DEPRECATED="/usr/lib/libFuzzingEngine.a"

# Argument passed to compiler to link against fuzzing engine.
# Defaults to the path, but is "-fsanitize=fuzzer" in libFuzzer builds.
ENV LIB_FUZZING_ENGINE="/usr/lib/libFuzzingEngine.a"

ENV ARCHITECTURE="x86_64"

# TODO: remove after tpm2 catchup.
ENV FUZZER_LDFLAGS=""

WORKDIR $SRC

# get version of aflplusplus v4.21c since double map is v4.21c taken from this version 
# to have a sound comparison
RUN git clone https://github.com/AFLplusplus/AFLplusplus.git aflplusplus && \
    cd aflplusplus && \
    git checkout 9f6b012 

RUN --mount=type=ssh \
  git clone git@github.com:tizianocolagrossi/AFLppDoubleMap.git /src/AFLppDoubleMap 

# Do precompiles before copying other scripts for better cache efficiency.
COPY aflppDriverNetdriver.patch /src/aflplusplus/
COPY aflppDriverNetdriver.patch /src/AFLppDoubleMap/
COPY precompile_aflpp /usr/local/bin/
RUN precompile_aflpp

COPY compile \
    # compile_plain \
    # compile_plain_sanitized \
    # compile_analysis \
    # compile_aflpp_analysis \
    # compile_aflppdouble_baseline \
    # compile_aflppdouble_enumetric \
    # compile_aflppdouble_enumetric++ \
    # compile_aflppdouble_enumetricbb++ \
    # compile_aflppdouble_enumetric_full \
    # # compile_baseline \
    # # compile_enumetric \
    # # compile_enumetric++ \
    # # compile_enumetricbb++ \
    # compile_aflpp_manual \
    # compile_aflpp \
    targets_list \
    /usr/local/bin/

CMD ["compile"]