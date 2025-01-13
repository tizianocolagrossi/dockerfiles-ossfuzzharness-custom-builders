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

RUN sed -i '/^#\sdeb-src /s/^#//' "/etc/apt/sources.list" 
RUN apt-get update && \
    apt-get install -y make autoconf automake libtool build-essential pkg-config bison flex gettext \
    libffi-dev liblzma-dev libtheora-dev libogg-dev zlib1g-dev libcairo2-dev libpcap-dev \
    python3-pip && \
    pip3 install meson==0.55.1 ninja==1.10.0.post2

# ADD https://ftp.gnome.org/pub/gnome/sources/glib/2.64/glib-2.64.2.tar.xz $SRC

RUN git clone https://gitlab.xiph.org/xiph/vorbis.git $SRC/vorbis/ && \
    cd $SRC/vorbis && \
    git checkout bb4047de4c05712bf1fd49b9584c360b8e4e0adf && \
    ./autogen.sh && \
    ./configure --enable-static && \
    make clean && \
    make -j$(nproc) && \
    make install

# RUN git clone --depth 1 --recursive https://gitlab.freedesktop.org/gstreamer/gstreamer.git gstreamer
# eacb7aa8  Release 1.18.4, while 44bdad 8 commit before
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