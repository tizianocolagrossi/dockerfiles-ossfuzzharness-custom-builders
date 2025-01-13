#!/bin/bash -eu

PREFIX=$WORK/prefix
mkdir -p $PREFIX

export PKG_CONFIG="`which pkg-config` --static"
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PATH=$PREFIX/bin:$PATH

echo "CFLAGS : " $CFLAGS
echo "CXXFLAGS : " $CXXFLAGS
PLUGIN_DIR=$PREFIX/lib/gstreamer-1.0

cd $SRC/gstreamer
meson setup \
    --prefix=$PREFIX \
    --libdir=lib \
    --default-library=static \
    -Db_lundef=false \
    -Ddoc=disabled \
    -Dexamples=disabled \
    -Dintrospection=disabled \
        _builddir .
ninja -C _builddir
ninja -C _builddir install

cd $SRC/gst-plugins-base
meson setup \
    --prefix=$PREFIX \
    --libdir=lib \
    --default-library=static \
    -Db_lundef=false \
    -Ddoc=disabled \
    -Dexamples=disabled \
    -Dintrospection=disabled \
        _builddir .
ninja -C _builddir
ninja -C _builddir install



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

echo
echo ">>>> BUILDING gst-discoverer"
echo
BUILD_CFLAGS="$CFLAGS `pkg-config --static --cflags $COMMON_DEPS $TARGET_DEPS`"
BUILD_LDFLAGS="-Wl,-static `pkg-config --static --libs $COMMON_DEPS $TARGET_DEPS`"

$CC $CFLAGS $BUILD_CFLAGS -c $SRC/gst-ci/fuzzing/gst-discoverer.c -o $SRC/gst-ci/fuzzing/gst-discoverer.o
$CXX $CXXFLAGS \
      -o $OUT/gst-discoverer \
      $PREDEPS_LDFLAGS \
      $SRC/gst-ci/fuzzing/gst-discoverer.o \
      $PLUGINS \
      $BUILD_LDFLAGS \
      $LIB_FUZZING_ENGINE \
      -Wl,-Bdynamic

ls $PREFIX/lib/gstreamer-1.0

echo " "
echo "$CC $CXX"
echo "PREDEPS_LDFLAGS $PREDEPS_LDFLAGS "
echo "BUILD_LDFLAGS $BUILD_LDFLAGS "
echo "LIB_FUZZING_ENGINE $LIB_FUZZING_ENGINE "
echo " "

ldd $OUT/gst-discoverer

exit 0
