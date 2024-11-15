# Copyright 2017 Google Inc.
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

FROM osvaldo/base-builder:v0.2.6tmp6-aflpp-doublem

RUN apt-get update && apt-get install -y make autoconf automake libpangocairo-1.0-0 libpango1.0-dev libtool libxml2-dev libcairo2-dev
RUN git clone https://github.com/imagemagick/imagemagick $SRC/imagemagick

ADD http://lcamtuf.coredump.cx/afl/demo/afl_testcases.tgz afl_testcases.tgz

WORKDIR $SRC/imagemagick
RUN git checkout tags/7.0.1-0

COPY build.sh encoder_list.cc encoder_fuzzer.cc crop_fuzzer.cc enhance_fuzzer.cc huffman_decode_fuzzer.cc rotate_fuzzer.cc $SRC/