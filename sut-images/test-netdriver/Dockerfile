# Copyright 2020 Google Inc.
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

FROM osvaldo/base-builder:latest

ENV HFND_TCP_PORT=4433
RUN chmod 777 /usr/lib &&\
    chmod 777 /opt

RUN git clone https://github.com/google/honggfuzz.git $SRC/honggfuzz  && \
    cd $SRC/honggfuzz && \
    git checkout 6f89ccc9c43c6c1d9f938c81a47b72cd5ada61ba 

RUN rm $SRC/honggfuzz/libhfnetdriver/netdriver.c
COPY netdriver.c $SRC/honggfuzz/libhfnetdriver/netdriver.c

RUN sed -i 's/int LLVMFuzzerTestOneInput/__attribute__((visibility(\"default\"))) int LLVMFuzzerTestOneInput/' $SRC/honggfuzz/libhfnetdriver/netdriver.c
RUN sed -i 's/int LLVMFuzzerInitialize/__attribute__((visibility(\"default\"))) int LLVMFuzzerInitialize/' $SRC/honggfuzz/libhfnetdriver/netdriver.c



RUN cd $SRC/honggfuzz && \
    CC=clang-13 CFLAGS="-fsanitize=fuzzer-no-link -fsanitize=address" make libhfcommon/libhfcommon.a && \
    CC=clang-13 CFLAGS="-fsanitize=fuzzer-no-link -fsanitize=address -DHFND_RECVTIME=1" make libhfnetdriver/libhfnetdriver.a && \
    mv libhfcommon/libhfcommon.a /usr/lib/libhfcommon.a && \
    mv libhfnetdriver/libhfnetdriver.a /usr/lib/libhfnetdriver.a

WORKDIR $SRC
COPY harness.cpp $SRC/
# COPY harness_fork.cpp $SRC/
COPY harness_while.cpp $SRC/
COPY build.sh $SRC/
    
    
