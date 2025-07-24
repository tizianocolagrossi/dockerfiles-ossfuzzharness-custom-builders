#!/bin/bash -eu

# This is intended to be run from OSS-Fuzz's build environment. We intend to
# eventually refactor it to be easy to run locally.

# build zlib
echo "=== Building zlib..."
pushd "$SRC/zlib"
make clean || echo "no clean"
./configure --prefix="$WORK" --static
make -j$(nproc) CFLAGS="$CFLAGS -fPIC"
make install
popd

# build xz
echo "=== Building xz..."
pushd "$SRC/xz"
make clean || echo "no clean"
./autogen.sh
PKG_CONFIG_PATH="$WORK/lib/pkgconfig" ./configure --disable-xz --disable-lzmadec --disable-lzmainfo --disable-lzma-links --disable-scripts --disable-doc --enable-static --disable-shared  --with-pic=yes --prefix="$WORK"
make -j$(nproc)
make install
popd

echo "=== Building libpng..."
pushd "$SRC/libpng"
make clean || echo "no clean"
autoreconf -fiv
PKG_CONFIG_PATH="$WORK/lib/pkgconfig" ./configure --enable-static --disable-shared  --prefix="$WORK" CPPFLAGS="-I$WORK/include" CFLAGS="$CFLAGS" LDFLAGS="${LDFLAGS:-} -L$WORK/lib"
make -j$(nproc)
make install
popd

# build libjpeg
echo "=== Building libjpeg..."
pushd "$SRC/libjpeg-turbo"
make clean || echo "no clean"
CFLAGS="$CFLAGS -fPIC" CMAKE_C_FLAGS="$CFLAGS" cmake . -DCMAKE_INSTALL_PREFIX="$WORK" -DENABLE_STATIC=1 -DENABLE_SHARED=0 -DWITH_JPEG8=1 -DWITH_SIMD=0 
make -j$(nproc)
make install
popd

# Build libtiff
echo "=== Building libtiff..."
pushd "$SRC/libtiff"
make clean || echo "no clean"
autoreconf -fiv
PKG_CONFIG_PATH="$WORK/lib/pkgconfig" ./configure CPPFLAGS="-I$WORK/include" CFLAGS="$CFLAGS" LDFLAGS="${LDFLAGS:-} -L$WORK/lib" --enable-static --disable-shared  --prefix="$WORK"
make -j$(nproc)
make install
popd

# Build liblcms2
echo "=== Building lcms..."
pushd "$SRC/Little-CMS"
make clean || echo "no clean"
autoreconf -fiv
PKG_CONFIG_PATH="$WORK/lib/pkgconfig" ./configure CPPFLAGS="-I$WORK/include" CFLAGS="$CFLAGS" LDFLAGS="${LDFLAGS:-} -L$WORK/lib" --enable-static --disable-shared  --prefix="$WORK"
make -j$(nproc)
make install
popd

# Build freetype2
echo "=== Building freetype2..."
# pushd "$SRC/freetype2"
pushd "$SRC/freetype2"
make clean || echo "no clean"
./autogen.sh
PKG_CONFIG_PATH="$WORK/lib/pkgconfig" ./configure CPPFLAGS="-I$WORK/include" CFLAGS="$CFLAGS" LDFLAGS="${LDFLAGS:-} -L$WORK/lib"  --enable-static --disable-shared --prefix="$WORK" --enable-freetype-config
make -j$(nproc)
make install
popd

# Build webp
echo "=== Building webp..."
pushd "$SRC/libwebp"
make clean || echo "no clean"
./autogen.sh
PKG_CONFIG_PATH="$WORK/lib/pkgconfig" ./configure CPPFLAGS="-I$WORK/include" CFLAGS="$CFLAGS" LDFLAGS="${LDFLAGS:-} -L$WORK/lib" --enable-static --disable-shared  --enable-libwebpmux --prefix="$WORK" CFLAGS="$CFLAGS -fPIC"
make -j$(nproc)
make install
popd

pushd "$SRC/lzma"
echo "=== Building lzma..."
chmod +x ./autogen.sh
make clean || echo "no clean"
./autogen.sh
PKG_CONFIG_PATH="$WORK/lib/pkgconfig" ./configure CPPFLAGS="-I$WORK/include" CFLAGS="$CFLAGS" LDFLAGS="${LDFLAGS:-} -L$WORK/lib" --enable-static --disable-shared --prefix="$WORK" CFLAGS="$CFLAGS -fPIC"
make -j$(nproc)
make install
popd

# freetype-config is in $WORK/bin so we temporarily add $WORK/bin to the path
echo "=== Building GraphicsMagick..."
make clean || echo "no clean"
PATH=$WORK:$WORK/bin:$PATH PKG_CONFIG_PATH="$WORK/lib/pkgconfig" ./configure CPPFLAGS="$CXXFLAGS -I$WORK/include/libpng16 -I$WORK/include/freetype2 -I$WORK/include" CFLAGS="$CFLAGS" LDFLAGS="${LDFLAGS:-} -L$WORK/lib" --prefix="$WORK" --enable-static --disable-shared  --without-perl --with-quantum-depth=16
make "-j$(nproc)"
make install
