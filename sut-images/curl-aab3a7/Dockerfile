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

RUN git clone https://github.com/curl/curl.git /src/curl
WORKDIR /src/curl
RUN git checkout aab3a7
RUN git clone https://github.com/curl/curl-fuzzer.git /src/curl_fuzzer
WORKDIR /src/curl_fuzzer
RUN git checkout afd24513a524a26086ef0c1b74f7c6da6d72bd9c
# RUN git checkout 8c348ecfe15c644d5b7f2456f2e9614808cdebac

RUN rm /src/curl_fuzzer/scripts/download_zlib.sh
COPY download_zlib.sh /src/curl_fuzzer/scripts/

RUN rm /src/curl_fuzzer/scripts/check_data.sh
COPY check_data.sh /src/curl_fuzzer/scripts/

# Use curl-fuzzer's scripts to get latest dependencies.
RUN $SRC/curl_fuzzer/scripts/ossfuzzdeps.sh

WORKDIR $SRC/curl_fuzzer
COPY build.sh $SRC/