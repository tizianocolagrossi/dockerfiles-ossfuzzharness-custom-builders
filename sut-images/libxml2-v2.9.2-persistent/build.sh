#!/bin/bash -eu
#
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

# fuzz/oss-fuzz-build.sh

export PKG_CONFIG="`which pkg-config` --static"
# export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

pushd $SRC/libxml2

rm -rf BUILD
cp -rf . $SRC/BUILD
mv $SRC/BUILD .

cd BUILD 
./autogen.sh
 CCLD="$CXX $CXXFLAGS" ./configure --disable-shared
 make -j$(nproc)

set -x
$CXX $CXXFLAGS -std=c++11  $SRC/target.cc -I $SRC/libxml2/BUILD/include $SRC/libxml2/BUILD/.libs/libxml2.a -lz -llzma -o $OUT/xml
cp $(ldd $OUT/xml | cut -d" " -f3) $OUT

mkdir $SRC/corpus
echo "hi" > $SRC/corpus/seed
zip -j $OUT/xml_seed_corpus.zip $SRC/corpus/*

popd