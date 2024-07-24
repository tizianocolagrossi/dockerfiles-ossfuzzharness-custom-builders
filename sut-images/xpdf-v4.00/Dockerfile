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

FROM base-builder:v0.2.6tmp5-lafl0.12
RUN git clone --depth 1 https://gitlab.freedesktop.org/freetype/freetype
RUN apt-get update
RUN apt-get install --no-install-recommends -y make wget cmake qtbase5-dev libcups2-dev autoconf automake autotools-dev libtool
RUN wget https://github.com/unifuzz/unibench/raw/834f2975d9fe605691159b22304b8897569e0549/xpdf-4.00.tar.gz

WORKDIR $SRC
COPY fuzz_*.cc $SRC/
COPY build.sh $SRC/
COPY fuzz_*.options $SRC/
COPY CMakeLists.txt.xpdf $SRC/
