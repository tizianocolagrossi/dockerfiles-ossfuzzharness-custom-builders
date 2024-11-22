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

FROM osvaldo/base-builder:v0.2.6tmp6-aflpp-doublem

RUN apt-get install -y make autoconf automake libtool build-essential \
    libass-dev libfreetype6-dev libsdl1.2-dev \
    libvdpau-dev libxcb1-dev libxcb-shm0-dev libogg-dev\
    pkg-config texinfo libbz2-dev zlib1g-dev nasm yasm cmake mercurial wget \
    xutils-dev libpciaccess-dev

RUN git clone https://git.ffmpeg.org/ffmpeg.git $SRC/ffmpeg
WORKDIR $SRC/ffmpeg
RUN git checkout tags/n3.1.3

WORKDIR $SRC

RUN wget https://www.alsa-project.org/files/pub/lib/alsa-lib-1.1.0.tar.bz2
# RUN git clone https://gitlab.freedesktop.org/mesa/drm.git $SRC/drm

RUN git clone https://github.com/mstorsjo/fdk-aac.git $SRC/fdk-aac
RUN wget https://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz/download -O lame.tar.gz
RUN git clone https://gitlab.freedesktop.org/xorg/lib/libXext $SRC/libXext

RUN git clone https://gitlab.freedesktop.org/xorg/lib/libxfixes.git $SRC/libXfixes
RUN git clone https://anongit.freedesktop.org/git/libva.git $SRC/libva
RUN git clone https://gitlab.freedesktop.org/aplattner/libvdpau.git $SRC/libvdpau
RUN git clone https://chromium.googlesource.com/webm/libvpx $SRC/libvpx

RUN git clone https://github.com/xiph/ogg.git $SRC/ogg
RUN git clone https://github.com/xiph/opus.git $SRC/opus
RUN git clone https://github.com/xiph/theora.git $SRC/theora

RUN git clone https://github.com/xiph/vorbis.git $SRC/vorbis
RUN git clone https://code.videolan.org/videolan/x264.git $SRC/x264

RUN git clone https://github.com/videolan/x265.git $SRC/x265

# WORKDIR $SRC/drm
# RUN git checkout a44c9c31

WORKDIR $SRC/fdk-aac
RUN git checkout 74c1a2a

WORKDIR $SRC/libXext
RUN git checkout efdcbb76

WORKDIR $SRC/libXfixes
RUN git checkout b2406ed9

WORKDIR $SRC/libva
RUN git checkout c401686a72042b64973540f8c64c84f988e00d6b

WORKDIR $SRC/libvdpau
RUN git checkout af517f56

WORKDIR $SRC/libvpx
RUN git checkout 042572177b5c58404836fce3fc221fd077dcd896	

WORKDIR $SRC/opus
RUN git checkout 655cc54

WORKDIR $SRC/theora
RUN git checkout a30b39c

WORKDIR $SRC/vorbis
RUN git checkout f409320

WORKDIR $SRC/x264
RUN git checkout e6a3f2989dd9eba3434c21fa94a6d9a5d1c7a9fe

WORKDIR $SRC/x265
RUN git checkout e34f489

WORKDIR $SRC/ogg
RUN git checkout 23264ee60baa66c5f627e05f1917ba99d422d258



WORKDIR $SRC
COPY build.sh $SRC/