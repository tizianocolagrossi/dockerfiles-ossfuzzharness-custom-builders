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

ENV HFND_TCP_PORT=8554
RUN chmod 777 /usr/lib &&\
    chmod 777 /opt

COPY fuzzing.patch $SRC/fuzzing.patch
COPY rtsp.dict $SRC/rtsp.dict
COPY live.2021.08.13.tar.gz $SRC/
COPY testOnDemandRTSPServer_seed_corpus.zip $SRC/

# Download Live555
RUN cd $SRC && \
    tar -zxvf live.2021.08.13.tar.gz && \
    chmod 777 -R live

WORKDIR $SRC
COPY build.sh $SRC/
    
    
