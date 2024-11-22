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

RUN apt-get update && \
   apt-get install -y make autoconf automake libtool build-essential pkg-config bison flex gettext \
    libffi-dev liblzma-dev libtheora-dev libogg-dev zlib1g-dev libcairo2-dev \
    python3-pip ninja-build && \
    pip3 install meson==0.55.1

ADD https://ftp.gnome.org/pub/gnome/sources/glib/2.64/glib-2.64.2.tar.xz $SRC

# Checkout all development repositories
#RUN for i in orc  gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav; do git clone --depth 1 --recursive https://anongit.freedesktop.org/git/gstreamer/$i $i; done  
RUN \
  git clone https://gitlab.freedesktop.org/gstreamer/gstreamer.git /src/gstreamer && \
  git clone https://gitlab.freedesktop.org/gstreamer/gst-plugins-base.git /src/gst-plugins-base && \
  git clone https://gitlab.freedesktop.org/gstreamer/gst-ci.git /src/gst-ci

RUN git clone https://gitlab.xiph.org/xiph/vorbis.git $SRC/vorbis/ && \
    cd $SRC/vorbis && \
    git checkout bb4047de4c05712bf1fd49b9584c360b8e4e0adf && \
    ./autogen.sh && \
    ./configure --enable-static && \
    make clean && \
    make -j$(nproc) && \
    make install

WORKDIR /src/gstreamer
RUN git checkout 44bdad
RUN git submodule update --init --recursive

WORKDIR /src/gst-plugins-base
RUN git checkout 01d1bbd1dadf2992769d351023d624eacb0a92c5
RUN git submodule update --init --recursive

WORKDIR /src/gst-ci
RUN git checkout 8f8cd9ec4b940a01bfbc38be260f9cccfed9b7a4
RUN git submodule update --init --recursive
RUN rm /src/gst-ci/fuzzing/build-oss-fuzz.sh
COPY build-oss-fuzz.sh $SRC/gst-ci/fuzzing/build-oss-fuzz.sh

WORKDIR /src/gstreamer
COPY build.sh $SRC/
