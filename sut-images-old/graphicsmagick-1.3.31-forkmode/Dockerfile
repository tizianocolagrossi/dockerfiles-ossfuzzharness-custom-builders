# Copyright 2018 Google Inc.
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

RUN apt-get clean

RUN apt-get update && apt-get install -y mercurial automake autopoint cmake libtool nasm pkg-config po4a doxygen libharfbuzz-dev libsharp-dev python3-pip 
RUN pip3 install meson==0.55 ninja
RUN hg clone -v http://hg.code.sf.net/p/graphicsmagick/code $SRC/graphicsmagick || \
    hg clone -v http://hg.code.sf.net/p/graphicsmagick/code $SRC/graphicsmagick || \
    hg clone -v http://hg.code.sf.net/p/graphicsmagick/code $SRC/graphicsmagick

RUN git clone https://gitlab.com/libtiff/libtiff $SRC/libtiff && cd $SRC/libtiff && git checkout b8eac98d
RUN git clone https://github.com/webmproject/libwebp $SRC/libwebp && cd $SRC/libwebp && git checkout tags/v1.0.1
RUN git clone https://github.com/madler/zlib $SRC/zlib && cd $SRC/zlib && git checkout cacf7f1
RUN git clone --depth 1 https://github.com/xz-mirror/xz
RUN git clone https://github.com/facebook/zstd $SRC/zstd && cd $SRC/zstd && git checkout 21cd8a9
RUN git clone https://github.com/libjpeg-turbo/libjpeg-turbo && cd $SRC/libjpeg-turbo && git checkout bb3d325
RUN git clone https://github.com/aseprite/freetype2.git && cd $SRC/freetype2 && git checkout 86bc8a9
RUN git clone https://github.com/pnggroup/libpng $SRC/libpng && cd $SRC/libpng && git checkout c17d164
RUN git clone https://github.com/mm2/Little-CMS $SRC/Little-CMS && cd $SRC/Little-CMS && git checkout 29b019f
# RUN git clone https://git.ghostscript.com/ghostpdl.git
RUN git clone --depth 1 https://gitlab.com/federicomenaquintero/bzip2.git $SRC/bzip2 
RUN git clone https://github.com/ImageMagick/lzma.git $SRC/lzma && cd $SRC/lzma && git checkout d9ea14f70bd8e16e8020977752f92bd6f27570d0
RUN git clone https://github.com/harfbuzz/harfbuzz.git $SRC/harfbuzz && cd $SRC/harfbuzz && git checkout tags/2.1.1

WORKDIR $SRC/graphicsmagick
RUN hg update -r GraphicsMagick-1_3_31

RUN rm $SRC/graphicsmagick/fuzzing/oss-fuzz-build.sh
COPY oss-fuzz-build.sh $SRC/graphicsmagick/fuzzing/

COPY build.sh $SRC/