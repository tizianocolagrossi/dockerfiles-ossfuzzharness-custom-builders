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

RUN git clone https://github.com/openssl/openssl.git $SRC/openssl && \
    cd $SRC/openssl && git checkout c74188e 

COPY key.pem $SRC/key.pem
COPY cert.pem $SRC/cert.pem
COPY openssl_seed_corpus.zip $SRC/openssl_seed_corpus.zip
COPY tls.dict $SRC/tls.dict

WORKDIR $SRC
COPY build.sh $SRC/
    
    
