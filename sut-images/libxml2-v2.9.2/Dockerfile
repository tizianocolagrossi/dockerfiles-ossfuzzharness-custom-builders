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

FROM osvaldo/base-builder:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        make autoconf libtool pkg-config \
        zlib1g-dev zlib1g-dev:i386 liblzma-dev liblzma-dev:i386 python-dev python3-dev
# Build requires automake 1.16.3
RUN curl -LO http://mirrors.kernel.org/ubuntu/pool/main/a/automake-1.16/automake_1.16.5-1.3_all.deb && \
    apt install ./automake_1.16.5-1.3_all.deb
RUN git clone https://gitlab.gnome.org/GNOME/libxml2.git $SRC/libxml2
# same version of fuzzbench and harness taken from google/fuzzer-test-suite
WORKDIR $SRC/libxml2
RUN git checkout tags/v2.9.2 
COPY build.sh $SRC/
COPY target.cc $SRC/
COPY xml.dict /out/