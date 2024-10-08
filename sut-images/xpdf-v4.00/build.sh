#!/bin/bash
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

# Unpack the file and cd into it

tar -xvzf xpdf-4.00.tar.gz
dir_name=`tar -tzf xpdf-4.00.tar.gz  | head -1 | cut -f1 -d"/"`
cd $dir_name

PREFIX=$WORK/prefix
mkdir -p $PREFIX

BKCC=$CC
BKCXX=$CXX
BKCCC=$CCC
BKCFLAGS=$CFLAGS

export LDFLAGS="-Wl,--copy-dt-needed-entries"

export CC=clang-13
export CXX=clang++-13
export CCC=clang++-13
export CFLAGS=''

export PKG_CONFIG="`which pkg-config` --static"
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PATH=$PREFIX/bin:$PATH
pushd $SRC/freetype
# git fetch -pP
# git checkout e8ebfe98
./autogen.sh
./configure --prefix="$PREFIX" --disable-shared PKG_CONFIG_PATH="$PKG_CONFIG_PATH" --with-png=no --with-zlib=no 
make -j$(nproc)
make install
popd

export CC=$BKCC
export CXX=$BKCXX
export CCC=$BKCCC
export CFLAGS="$BKCFLAGS"

rm ./xpdf/CMakeLists.txt
cp $SRC/CMakeLists.txt.xpdf ./xpdf/CMakeLists.txt

# # # Make minor change in the CMakeFiles file.
# # sed -i 's/#--- object files needed by XpdfWidget/add_library(testXpdfStatic STATIC $<TARGET_OBJECTS:xpdf_objs>)\n#--- object files needed by XpdfWidget/' ./xpdf/CMakeLists.txt
# # sed -i 's/#--- pdftops/add_library(testXpdfWidgetStatic STATIC $<TARGET_OBJECTS:xpdf_widget_objs>\n $<TARGET_OBJECTS:splash_objs>\n $<TARGET_OBJECTS:xpdf_objs>\n ${FREETYPE_LIBRARY}\n ${FREETYPE_OTHER_LIBS})\n#--- pdftops/' ./xpdf/CMakeLists.txt

# Build the project
mkdir -p build && cd build && rm -rf *
export LD=$CXX
cmake ../ -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
  -DOPI_SUPPORT=ON -DSPLASH_CMYK=ON -DMULTITHREADED=ON \
  -DUSE_EXCEPTIONS=ON -DXPDFWIDGET_PRINTING=ON -DFREETYPE_DIR="$PREFIX"
make -j$(nproc)

# Build fuzzers
for fuzzer in pdfload ; do # JBIG2 zxdoc
    cp ../../fuzz_$fuzzer.cc .
    $CXX $CXXFLAGS -o $OUT/fuzz_$fuzzer \
    -I../ -I../goo -I../fofi -I. -I../xpdf -I../splash \
    fuzz_$fuzzer.cc \
    -Wl,--start-group -lgraphite2 ./xpdf/libtestXpdfStatic.a ./xpdf/libtestXpdfWidgetStatic.a ./splash/libsplash.a ./fofi/libfofi.a /work/prefix/lib/libfreetype.a $(find / -name libharfbuzz.a) ./goo/libgoo.a $LIB_FUZZING_ENGINE -Wl,--end-group

    
done

# mkdir -p $SRC/corpus
# git clone https://github.com/unifuzz/seeds.git $SRC/seeds
# for f in $SRC/seeds/general_evaluation/pdf/* ; do
#   s=$(sha1sum "$f" | awk '{print $1}')
#   cp $f $SRC/corpus/$s
# done

# for fuzzer in  pdfload ; do ## zxdoc JBIG2
#   zip -j $OUT/fuzz_${fuzzer}_seed_corpus.zip $SRC/corpus/*
# done
# Copy over options files
cp $SRC/fuzz_*.options $OUT/
