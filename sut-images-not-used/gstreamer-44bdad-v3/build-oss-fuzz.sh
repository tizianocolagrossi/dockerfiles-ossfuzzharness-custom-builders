#!/bin/bash -eux

# build-oss-fuzz.sh
#
# Build script which is executed by oss-fuzz build.sh
#
# $SRC: location of code checkouts
# $OUT: location to put fuzzing targets and corpus
# $WORK: writable directory where all compilation should be executed
#
# /!\ Do not override any CC, CXX, CFLAGS, ... variables
#

rm -rf $WORK/*

# Prefix where we will temporarily install everything
PREFIX=$WORK/prefix
mkdir -p $PREFIX
# always try getting the arguments for static compilation/linking
# Fixes GModule not being picked when gstreamer-1.0.pc is looked up by meson
# more or less https://github.com/mesonbuild/meson/pull/6629
export PKG_CONFIG="`which pkg-config` --static"
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PATH=$PREFIX/bin:$PATH

# Minimize gst-debug level/code
export CFLAGS="$CFLAGS -DGST_LEVEL_MAX=2"

echo "CFLAGS : " $CFLAGS
echo "CXXFLAGS : " $CXXFLAGS
PLUGIN_DIR=$PREFIX/lib/gstreamer-1.0

# Switch to work directory
cd $WORK

mkdir -p $OUT/lib/gstreamer-1.0

# build ogg
pushd $SRC/ogg
./autogen.sh
./configure --prefix="$PREFIX" --libdir="$PREFIX/lib"
make clean
make -j$(nproc)
make install
popd

# build vorbis
pushd $SRC/vorbis
./autogen.sh
./configure --prefix="$PREFIX" --libdir="$PREFIX/lib"
make clean
make -j$(nproc)
make install
popd

# build theora
pushd $SRC/theora
./autogen.sh
./configure --prefix="$PREFIX" --libdir="$PREFIX/lib"
make clean
make -j$(nproc)
make install
popd

# Note: We don't use/build orc since it still seems to be problematic
# with clang and the various sanitizers.

# For now we only build core and base. Add other modules when/if needed
for i in gstreamer gst-plugins-base;
do
    mkdir -p $i
    cd $SRC/$i
    ## error -Dtracer_hooks=false -Dregistry=false Unknown options
    meson setup \
        --prefix=$PREFIX \
        --libdir=lib \
        --default-library=static \
        -Db_lundef=false \
        -Ddoc=disabled \
        -Dexamples=disabled \
        -Dintrospection=disabled \
         _builddir $SRC/$i
    ninja -C _builddir
    ninja -C _builddir install
    cd ..
done

# 2) Build the target fuzzers

# All targets will be linked in with $LIB_FUZZING_ENGINE which contains the
# actual fuzzing runner. Anything fuzzing engine can be used provided it calls
# the same function as libfuzzer.

# Note: The fuzzer .o needs to be first compiled with CC and then linked with CXX

# We want to statically link everything, except for shared libraries
# that are present on the base image. Those need to be specified
# beforehand and explicitely linked dynamically If any of the static
# dependencies require a pre-installed shared library, you need to add
# that library to the following list
PREDEPS_LDFLAGS="-Wl,-Bdynamic -ldl -lm -pthread -lrt -lpthread"
COMMON_DEPS="glib-2.0 gio-2.0 gstreamer-1.0 gstreamer-app-1.0"

TARGET_DEPS=" gstreamer-pbutils-1.0 \
              gstreamer-video-1.0 \
              gstreamer-audio-1.0 \
              gstreamer-riff-1.0 \
              gstreamer-tag-1.0 \
              zlib ogg vorbis vorbisenc \
              theoraenc theoradec theora cairo"

PLUGINS="$PLUGIN_DIR/libgstcoreelements.a \
       $PLUGIN_DIR/libgsttypefindfunctions.a \
       $PLUGIN_DIR/libgstplayback.a \
       $PLUGIN_DIR/libgstapp.a \
       $PLUGIN_DIR/libgstvorbis.a \
       $PLUGIN_DIR/libgsttheora.a \
       $PLUGIN_DIR/libgstogg.a"

LIB_M=$(find /usr/lib /usr/lib64 -name "libm.a")

echo
echo ">>>> BUILDING gst-discoverer"
echo
BUILD_CFLAGS="$CFLAGS `pkg-config --static --cflags $COMMON_DEPS $TARGET_DEPS`"
BUILD_LDFLAGS="-Wl,-static `pkg-config --static --libs $COMMON_DEPS $TARGET_DEPS`"

$CC $CFLAGS $BUILD_CFLAGS -c $SRC/gst-ci/fuzzing/gst-discoverer.c $LIB_M -o $SRC/gst-ci/fuzzing/gst-discoverer.o
$CXX $CXXFLAGS \
      -o $OUT/gst-discoverer \
      $PREDEPS_LDFLAGS \
      $SRC/gst-ci/fuzzing/gst-discoverer.o $LIB_M\
      $PLUGINS \
      $BUILD_LDFLAGS \
      $LIB_FUZZING_ENGINE \
      -Wl,-Bdynamic

# copy out the fuzzing binaries
for BINARY in $(find _builddir/ci/fuzzing -type f -executable -print)
do
  BASENAME=${BINARY##*/}
  rm -rf "$OUT/$BASENAME*"
  cp $BINARY $OUT/$BASENAME
  patchelf --set-rpath '$PLUGIN_DIR/lib' $OUT/$BASENAME
done

# # # copy any relevant corpus
# # for CORPUS in $(find "$SRC/gstreamer/ci/fuzzing" -type f -name "*.corpus"); do
# #   BASENAME=${CORPUS##*/}
# #   pushd "$SRC/gstreamer"
# #   zip $OUT/${BASENAME%%.*}_seed_corpus.zip . -ws -r -i@$CORPUS
# #   popd
# # done

# copy dependant libraries
find "$PREFIX/lib" -maxdepth 1 -type f -name "*.so*" -exec cp -d "{}" $OUT/lib \; -print
# add rpath that point to the correct place to all shared libraries
find "$OUT/lib" -maxdepth 1 -type f -name "*.so*" -exec patchelf --debug --set-rpath '$ORIGIN' {} \;
find "$PREFIX/lib" -maxdepth 1 -type l -name "*.so*" -exec cp -d "{}" $OUT/lib \; -print

find "$PREFIX/lib/gstreamer-1.0" -maxdepth 1 -type f -name "*.so" -exec cp -d "{}" $OUT/lib/gstreamer-1.0 \;
find "$OUT/lib/gstreamer-1.0" -type f -name "*.so*" -exec patchelf --debug --set-rpath '$ORIGIN/..' {} \;

# make it easier to spot dependency issues
find "$OUT/lib/gstreamer-1.0" -maxdepth 1 -type f -name "*.so" -print -exec ldd {} \;