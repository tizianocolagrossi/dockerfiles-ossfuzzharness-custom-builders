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

FROM osvaldo/sgfuzzer-builder:latest

ENV HFND_TCP_PORT=8554
RUN chmod 777 /usr/lib &&\
    chmod 777 /opt


RUN git clone https://github.com/google/honggfuzz.git $SRC/honggfuzz  && \
    cd $SRC/honggfuzz && \
    git checkout 6f89ccc9c43c6c1d9f938c81a47b72cd5ada61ba 

RUN sed -i 's/int LLVMFuzzerTestOneInput/__attribute__((visibility(\"default\"))) int LLVMFuzzerTestOneInput/' $SRC/honggfuzz/libhfnetdriver/netdriver.c
RUN sed -i 's/int LLVMFuzzerInitialize/__attribute__((visibility(\"default\"))) int LLVMFuzzerInitialize/' $SRC/honggfuzz/libhfnetdriver/netdriver.c

RUN cd $SRC/honggfuzz && \
    CFLAGS="-fsanitize=fuzzer-no-link -fsanitize=address" make libhfcommon/libhfcommon.a && \
    CFLAGS="-fsanitize=fuzzer-no-link -fsanitize=address -DHFND_RECVTIME=1" make libhfnetdriver/libhfnetdriver.a && \
    mv libhfcommon/libhfcommon.a /usr/lib/libhfcommon.a && \
    mv libhfnetdriver/libhfnetdriver.a /usr/lib/libhfnetdriver.a


COPY fuzzing.patch $SRC/fuzzing.patch
COPY rtsp.dict $SRC/rtsp.dict
COPY live.2021.08.13.tar.gz $SRC/
COPY blocked_variables.txt $SRC/blocked_variables.txt
COPY testOnDemandRTSPServer_seed_corpus.zip $SRC/

# Download Live555
RUN cd $SRC && \
    tar -zxvf live.2021.08.13.tar.gz && \
    chmod 777 -R live

WORKDIR $SRC
COPY build.sh $SRC/
    
    
