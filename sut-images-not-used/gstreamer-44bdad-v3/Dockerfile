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
   apt-get install -y make autoconf automake libtool build-essential pkg-config bison flex patchelf \
   libgsl-dev libgmp-dev libunwind-dev libdw-dev bash-completion libbz2-dev libebackend1.2-dev elfutils \
    python3-pip ninja-build && \
   pip3 install meson==0.55.1

RUN apt-get update && \
   apt-get install -y gettext libffi-dev liblzma-dev zlib1g-dev libcairo2-dev libgraphene-1.0-dev 

RUN git clone https://gitlab.xiph.org/xiph/vorbis.git $SRC/vorbis/ && \
   cd $SRC/vorbis && git checkout bb4047de4c05712bf1fd49b9584c360b8e4e0adf
   
RUN git clone https://gitlab.xiph.org/xiph/ogg.git $SRC/ogg && \
    cd $SRC/ogg && git checkout e1774cd7

RUN git clone https://gitlab.xiph.org/xiph/theora.git $SRC/theora && \
    cd $SRC/theora && git checkout c5a83d0a24720ef1136616c59275c9d32aabfeb7

RUN git clone https://gitlab.freedesktop.org/gstreamer/gstreamer.git $SRC/gstreamer && \
    cd $SRC/gstreamer && \
    git checkout tags/1.18.4

RUN git clone https://gitlab.freedesktop.org/gstreamer/gst-plugins-base.git $SRC/gst-plugins-base && \
    cd $SRC/gst-plugins-base && \
    git checkout ce69d106 && \ 
    cd $SRC/gst-plugins-base/subprojects && \
    git clone https://gitlab.freedesktop.org/gstreamer/meson-ports/gl-headers.git && \
    git clone https://github.com/ebassi/graphene.git && \
    cd graphene && \
    git checkout ecf418f && \
    git submodule update --init && \
    cd subprojects/mutest && \
    git checkout 3c1b104390452ef09848fdb8aae29892f9ce182b

RUN git clone https://gitlab.freedesktop.org/gstreamer/gst-ci.git $SRC/gst-ci && \
    cd $SRC/gst-ci && \
    git checkout 89050a82223a6d7ce5bb888d969b54a104942692

RUN rm /src/gst-ci/fuzzing/build-oss-fuzz.sh
COPY build-oss-fuzz.sh $SRC/gst-ci/fuzzing/build-oss-fuzz.sh

WORKDIR /src/gstreamer
COPY build.sh $SRC/