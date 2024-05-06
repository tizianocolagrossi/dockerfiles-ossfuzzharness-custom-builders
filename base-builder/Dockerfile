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

FROM oss-base-clang

COPY install_deps.sh /
RUN /install_deps.sh && rm /install_deps.sh

ARG enumetric-version=v0.2.4

RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN --mount=type=ssh \
  git clone git@github.com:tizianocolagrossi/Enumetric.git /src/Enumetric

RUN --mount=type=ssh \
  git clone git@github.com:tizianocolagrossi/LibAFL.git /src/LibAFL

COPY checkout_build_enumetric.sh /root/
# # Keep all steps in the same script to decrease the number of intermediate
# # layes in docker file.
RUN /root/checkout_build_enumetric.sh $enumetric-version
RUN rm /root/checkout_build_enumetric.sh

RUN ln -s /usr/bin/llvm-profdata-13 /usr/bin/llvm-profdata

# Build and install latest Python 3 (3.8.3).
ENV PYTHON_VERSION 3.8.3
RUN export PYTHON_DEPS="\
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \
        libnss3-dev \
        libssl-dev \
        libsqlite3-dev \
        libreadline-dev \
        libffi-dev \
        libbz2-dev \
        liblzma-dev" && \
    unset CFLAGS CXXFLAGS && \
    apt-get install -y $PYTHON_DEPS && \
    cd /tmp && \
    curl -O https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz && \
    tar -xvf Python-$PYTHON_VERSION.tar.xz && \
    cd Python-$PYTHON_VERSION && \
    ./configure --enable-optimizations --enable-shared && \
    make -j install && \
    ldconfig && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    cd .. && \
    rm -r /tmp/Python-$PYTHON_VERSION.tar.xz /tmp/Python-$PYTHON_VERSION && \
    rm -rf /usr/local/lib/python3.8/test && \
    apt-get remove -y $PYTHON_DEPS # https://github.com/google/oss-fuzz/issues/3888


# Default build flags for various sanitizers.
ENV SANITIZER_FLAGS_address "-fsanitize=address -fsanitize-address-use-after-scope"
ENV SANITIZER_FLAGS_hwaddress "-fsanitize=hwaddress -fuse-ld=lld -Wno-unused-command-line-argument"

# Set of '-fsanitize' flags matches '-fno-sanitize-recover' + 'unsigned-integer-overflow'.
ENV SANITIZER_FLAGS_undefined "-fsanitize=array-bounds,bool,builtin,enum,function,integer-divide-by-zero,null,object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,unsigned-integer-overflow,unreachable,vla-bound,vptr -fno-sanitize-recover=array-bounds,bool,builtin,enum,function,integer-divide-by-zero,null,object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,unreachable,vla-bound,vptr"

# Don't include "function" since it is unsupported on aarch64.
ENV SANITIZER_FLAGS_undefined_aarch64 "-fsanitize=array-bounds,bool,builtin,enum,integer-divide-by-zero,null,object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,unsigned-integer-overflow,unreachable,vla-bound,vptr -fno-sanitize-recover=array-bounds,bool,builtin,enum,integer-divide-by-zero,null,object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,unreachable,vla-bound,vptr"

ENV SANITIZER_FLAGS_memory "-fsanitize=memory -fsanitize-memory-track-origins"

ENV SANITIZER_FLAGS_thread "-fsanitize=thread"

ENV SANITIZER_FLAGS_introspector "-O0 -flto -fno-inline-functions -fuse-ld=gold -Wno-unused-command-line-argument"

# Do not use any sanitizers in the coverage build.
ENV SANITIZER_FLAGS_coverage ""

# We use unsigned-integer-overflow as an additional coverage signal and have to
# suppress error messages. See https://github.com/google/oss-fuzz/issues/910.
ENV UBSAN_OPTIONS="silence_unsigned_overflow=1"

# To suppress warnings from binaries running during compilation.
ENV DFSAN_OPTIONS='warn_unimplemented=0'

# Default build flags for coverage feedback.
ENV COVERAGE_FLAGS="-fsanitize=fuzzer-no-link"

# Use '-Wno-unused-command-line-argument' to suppress "warning: -ldl: 'linker' input unused"
# messages which are treated as errors by some projects.
ENV COVERAGE_FLAGS_coverage "-fprofile-instr-generate -fcoverage-mapping -pthread -Wl,--no-as-needed -Wl,-ldl -Wl,-lm -Wno-unused-command-line-argument"

# Default sanitizer, fuzzing engine and architecture to use.
ENV SANITIZER="address"
ENV FUZZING_ENGINE="libafl-enumetric"
ENV ARCHITECTURE="x86_64"

# DEPRECATED - NEW CODE SHOULD NOT USE THIS. OLD CODE SHOULD STOP. Please use
# LIB_FUZZING_ENGINE instead.
# Path to fuzzing engine library to support some old users of
# LIB_FUZZING_ENGINE.
ENV LIB_FUZZING_ENGINE_DEPRECATED="/usr/lib/libFuzzingEngine.a"

# Argument passed to compiler to link against fuzzing engine.
# Defaults to the path, but is "-fsanitize=fuzzer" in libFuzzer builds.
ENV LIB_FUZZING_ENGINE="/usr/lib/libFuzzingEngine.a"

# TODO: remove after tpm2 catchup.
ENV FUZZER_LDFLAGS ""

WORKDIR $SRC

COPY compile \
    compile_analysis \
    compile_baseline \
    compile_enumetric \
    compile_enumetric++ \
    targets_list \
    /usr/local/bin/

CMD ["compile"]