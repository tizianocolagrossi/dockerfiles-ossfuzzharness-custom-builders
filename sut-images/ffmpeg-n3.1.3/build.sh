#!/bin/bash -eux
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


export LDFLAGS="$FUZZER_LDFLAGS"

# Build dependencies.
export FFMPEG_DEPS_PATH=$SRC/ffmpeg_deps
mkdir -p $FFMPEG_DEPS_PATH

echo ""
echo "BUILDING alsa lib 1.1.0"
echo ""

cd $SRC
cp alsa-lib-1.1.0.tar.bz2 alsa-lib-1.1.0cp.tar.bz2
bzip2 -f -d alsa-lib-1.1.0cp.tar.bz2
tar xf alsa-lib-1.1.0cp.tar
cd alsa-lib-1.1.0
./configure --prefix="$FFMPEG_DEPS_PATH" --enable-static --disable-shared
make clean
make -j$(nproc) all
make install

cd $SRC/fdk-aac
autoreconf -fiv
./configure --prefix="$FFMPEG_DEPS_PATH" --disable-shared
make clean
make -j$(nproc) all
make install


# # cd $SRC/drm
# # # Requires xutils-dev libpciaccess-dev
# # ./autogen.sh
# # ./configure --prefix="$FFMPEG_DEPS_PATH" --enable-static
# # make clean
# # make -j$(nproc)
# # make install

# echo ""
# echo "BUILDING libva"
# echo ""

# cd $SRC/libva # need lib drm
# ./autogen.sh
# ./configure --prefix="$FFMPEG_DEPS_PATH" --enable-static --disable-shared
# make clean
# make -j$(nproc) all
# make install

################################################
echo ""
echo "BUILDING alsa lame-3.99.5"
echo ""

cd $SRC
tar xzf lame.tar.gz
cd lame-*
./configure --prefix="$FFMPEG_DEPS_PATH" --enable-static
make clean
make -j$(nproc)
make install

echo ""
echo "BUILDING libXext"
echo ""

cd $SRC/libXext
./autogen.sh
./configure --prefix="$FFMPEG_DEPS_PATH" --enable-static
make clean
make -j$(nproc)
make install


echo ""
echo "BUILDING libXfixes"
echo ""

cd $SRC/libXfixes
./autogen.sh
./configure --prefix="$FFMPEG_DEPS_PATH" --enable-static
make clean
make -j$(nproc)
make install

echo ""
echo "BUILDING libvdpau"
echo ""

cd $SRC/libvdpau
./autogen.sh
./configure --prefix="$FFMPEG_DEPS_PATH" --enable-static --disable-shared
make clean
make -j$(nproc) all
make install

echo ""
echo "BUILDING libvpx"
echo ""

cd $SRC/libvpx
LDFLAGS="$CXXFLAGS $LDFLAGS" ./configure --prefix="$FFMPEG_DEPS_PATH" \
    --disable-examples --disable-unit-tests
make clean
make -j$(nproc) all
make install

echo ""
echo "BUILDING ogg"
echo ""

cd $SRC/ogg
./autogen.sh
./configure --prefix="$FFMPEG_DEPS_PATH" --enable-static
make clean
make -j$(nproc)
make install

echo ""
echo "BUILDING opus"
echo ""

cd $SRC/opus
./autogen.sh
./configure --prefix="$FFMPEG_DEPS_PATH" --enable-static
make clean
make -j$(nproc) all
make install


echo ""
echo "BUILDING theora"
echo ""

cd $SRC/theora # need ogg
# theora requires ogg, need to pass its location to the "configure" script.
CFLAGS="$CFLAGS -fPIC" LDFLAGS="$LDFLAGS -L$FFMPEG_DEPS_PATH/lib/" \
    CPPFLAGS="$CXXFLAGS -I$FFMPEG_DEPS_PATH/include/" \
    LD_LIBRARY_PATH="$FFMPEG_DEPS_PATH/lib/" \
    ./autogen.sh --prefix="$FFMPEG_DEPS_PATH" --enable-static --disable-examples
make clean
make -j$(nproc)
make install


echo ""
echo "BUILDING vorbis"
echo ""

cd $SRC/vorbis
./autogen.sh
./configure --prefix="$FFMPEG_DEPS_PATH" --enable-static
make clean
make -j$(nproc)
make install

echo ""
echo "BUILDING x264"
echo ""
ls
echo ""

cd $SRC/x264
ls 
LDFLAGS="$CXXFLAGS $LDFLAGS" ./configure --prefix="$FFMPEG_DEPS_PATH" \
    --enable-static
make clean
make -j$(nproc)
make install

echo ""
echo "BUILDING x265"
echo ""

cd $SRC/x265/build/linux
cmake -G "Unix Makefiles" \
    -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX \
    -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
    -DCMAKE_EXE_LINKER_FLAGS="$FUZZER_LDFLAGS" \
    -DCMAKE_INSTALL_PREFIX="$FFMPEG_DEPS_PATH" -DENABLE_SHARED:bool=off \
    ../../source
make clean
make -j$(nproc) x265-static
make install

# Remove shared libraries to avoid accidental linking against them.
rm $FFMPEG_DEPS_PATH/lib/*.so
rm $FFMPEG_DEPS_PATH/lib/*.so.*

# Build the target.
cd $SRC/ffmpeg
PKG_CONFIG_PATH="$FFMPEG_DEPS_PATH/lib/pkgconfig" ./configure \
    --cc=$CC --cxx=$CXX --ld="$CXX $CXXFLAGS -std=c++11" \
    --extra-cflags="-I$FFMPEG_DEPS_PATH/include" \
    --extra-ldflags="-L$FFMPEG_DEPS_PATH/lib" \
    --prefix="$FFMPEG_DEPS_PATH" \
    --pkg-config-flags="--static" \
    --enable-gpl \
    --enable-libass \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libtheora \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libx264 \
    --enable-nonfree \
    --disable-shared
make clean
make -j$(nproc) install
    # --enable-libx265 \

# # # Download test sampes, will be used as seed corpus.
# # export TEST_SAMPLES_PATH=$SRC/ffmpeg/fate-suite/
# # make fate-rsync SAMPLES=$TEST_SAMPLES_PATH

# Build the fuzzers.
cd $SRC/ffmpeg

export TEMP_VAR_CODEC="AV_CODEC_ID_H264"
export TEMP_VAR_CODEC_TYPE="VIDEO"

FFMPEG_FUZZERS_COMMON_FLAGS="-lfuzzer $FUZZER_LDFLAGS \
    -L$FFMPEG_DEPS_PATH/lib \
    -Llibavcodec -Llibavdevice -Llibavfilter -Llibavformat -Llibavresample \
    -Llibavutil -Llibpostproc -Llibswscale -Llibswresample \
    -Wl,--as-needed -Wl,-z,noexecstack -Wl,--warn-common \
    -Wl,-rpath-link=libpostproc:libswresample:libswscale:libavfilter:libavdevice:libavformat:libavcodec:libavutil:libavresample \
    -lavdevice -lavfilter -lavformat -lavcodec -lswresample -lswscale \
    -lavutil -ldl -lxcb -lxcb-shm -lxcb -lxcb-xfixes  -lxcb -lxcb-shape -lxcb \
    -lX11 -lasound -lm -lbz2 -lz -pthread -lva-x11 -lXext -lXfixes \
    -lx264 -lx265 -lvpx -lva -lvorbis -logg -lvorbisenc -lopus -lmp3lame \
    -lfdk-aac -ltheora -ltheoraenc -ltheoradec -lvdpau -lva-drm -ldrm"

# Build fuzzers for audio formats.
CODEC_TYPE="AUDIO"
CODEC_NAMES="AV_CODEC_ID_AAC \
  AV_CODEC_ID_AC3 \
  AV_CODEC_ID_ADPCM_ADX \
  AV_CODEC_ID_AMR_NB \
  AV_CODEC_ID_AMR_WB \
  AV_CODEC_ID_DTS \
  AV_CODEC_ID_EAC3 \
  AV_CODEC_ID_FLAC \
  AV_CODEC_ID_GSM_MS \
  AV_CODEC_ID_MP2 \
  AV_CODEC_ID_MP3 \
  AV_CODEC_ID_QCELP \
  AV_CODEC_ID_SIPR \
  AV_CODEC_ID_WAVPACK"

for codec in $CODEC_NAMES; do
  fuzzer_name=ffmpeg_${CODEC_TYPE}_${codec}_fuzzer

  $CC $CFLAGS -I${FFMPEG_DEPS_PATH}/include \
      $SRC/ffmpeg/doc/examples/decoding_encoding.c \
      -o $OUT/${fuzzer_name} \
      -DFFMPEG_CODEC=${codec} -DFUZZ_FFMPEG_${CODEC_TYPE}= \
      ${FFMPEG_FUZZERS_COMMON_FLAGS}

  echo -en "[libfuzzer]\nmax_len = 1000000\n" > $OUT/${fuzzer_name}.options
done

# # # Build fuzzers for subtitles formats.
# # CODEC_TYPE="SUBTITLE"
# # CODEC_NAMES="AV_CODEC_ID_DVD_SUBTITLE \
# #   AV_CODEC_ID_MOV_TEXT \
# #   AV_CODEC_ID_SUBRIP"

# # for codec in $CODEC_NAMES; do
# #   fuzzer_name=ffmpeg_${CODEC_TYPE}_${codec}_fuzzer

# #   $CC $CFLAGS -I${FFMPEG_DEPS_PATH}/include \
# #       $SRC/ffmpeg/doc/examples/decoder_targeted.c \
# #       -o $OUT/${fuzzer_name} \
# #       -DFFMPEG_CODEC=${codec} -DFUZZ_FFMPEG_${CODEC_TYPE}= \
# #       ${FFMPEG_FUZZERS_COMMON_FLAGS}
# # done

# # # Build fuzzers for video formats.
# # CODEC_TYPE="VIDEO"
# # CODEC_NAMES="AV_CODEC_ID_AMV \
# #   AV_CODEC_ID_BINTEXT \
# #   AV_CODEC_ID_BMP \
# #   AV_CODEC_ID_CINEPAK \
# #   AV_CODEC_ID_DVVIDEO \
# #   AV_CODEC_ID_ESCAPE130 \
# #   AV_CODEC_ID_FLIC \
# #   AV_CODEC_ID_FLV1 \
# #   AV_CODEC_ID_FRAPS \
# #   AV_CODEC_ID_GIF \
# #   AV_CODEC_ID_H263 \
# #   AV_CODEC_ID_H263I \
# #   AV_CODEC_ID_H264 \
# #   AV_CODEC_ID_INDEO2 \
# #   AV_CODEC_ID_INTERPLAY_VIDEO \
# #   AV_CODEC_ID_JPEGLS \
# #   AV_CODEC_ID_KMVC \
# #   AV_CODEC_ID_MDEC \
# #   AV_CODEC_ID_MJPEG \
# #   AV_CODEC_ID_MPEG1VIDEO \
# #   AV_CODEC_ID_MPEG2VIDEO \
# #   AV_CODEC_ID_MPEG4 \
# #   AV_CODEC_ID_MSVIDEO1 \
# #   AV_CODEC_ID_PCX \
# #   AV_CODEC_ID_PGM \
# #   AV_CODEC_ID_PICTOR \
# #   AV_CODEC_ID_PNG \
# #   AV_CODEC_ID_RPZA \
# #   AV_CODEC_ID_RV40 \
# #   AV_CODEC_ID_SANM \
# #   AV_CODEC_ID_SMC \
# #   AV_CODEC_ID_SUNRAST \
# #   AV_CODEC_ID_SVQ1 \
# #   AV_CODEC_ID_SVQ3 \
# #   AV_CODEC_ID_TARGA \
# #   AV_CODEC_ID_TIFF \
# #   AV_CODEC_ID_VP3 \
# #   AV_CODEC_ID_VP5 \
# #   AV_CODEC_ID_VP6 \
# #   AV_CODEC_ID_VP6F \
# #   AV_CODEC_ID_VP8 \
# #   AV_CODEC_ID_ZMBV"

# # for codec in $CODEC_NAMES; do
# #   fuzzer_name=ffmpeg_${CODEC_TYPE}_${codec}_fuzzer

# #   $CC $CFLAGS -I${FFMPEG_DEPS_PATH}/include \
# #       $SRC/ffmpeg/doc/examples/decode_video.c \
# #       -o $OUT/${fuzzer_name} \
# #       -DFFMPEG_CODEC=${codec} -DFUZZ_FFMPEG_${CODEC_TYPE}= \
# #       ${FFMPEG_FUZZERS_COMMON_FLAGS}

# #   echo -en "[libfuzzer]\nmax_len = 1000000\n" > $OUT/${fuzzer_name}.options
# # done

