#!/bin/bash -eu
# Copyright 2021 Google LLC
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

git checkout tags/v0.27.5
cp ./fuzz/fuzz-read-print-write.cpp $SRC
cp ./fuzz/exiv2.dict $SRC
git checkout tags/v0.26

git apply $SRC/exiv2-v0.26.diff

CXXFLAGS="--libafl -O1 -fno-omit-frame-pointer -gline-tables-only -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"

# Added to fix a false positive result: https://github.com/google/oss-fuzz/issues/6489
CXXFLAGS="${CXXFLAGS} -fno-sanitize=float-divide-by-zero"

# Build Exiv2
mkdir -p build
cd build
cmake -DEXIV2_ENABLE_SHARED=Off ..
make -j $(nproc)


mkdir fuzz
cd fuzz

$CXX $SRC/fuzz-read-print-write.cpp -lexiv2 -lz -lexpat -linih -lbrotlienc -lbrotlidec -lbrotlicommon -lxmp --libafl -L../src -L../xmpsdk -I ../ -I ../../include/ -o $OUT/fuzz-read-print-write


# Copy binary and dictionary to $OUT
cp $SRC/exiv2.dict $OUT/fuzz-read-print-write.dict

# Initialize the corpus, using the files in test/data
# mkdir corpus
# for f in $(find ../test/data -type f -size -20k); do
#     s=$(sha1sum "$f" | awk '{print $1}')
#     cp $f corpus/$s
# done
mkdir $SRC/corpus
git clone https://github.com/unifuzz/seeds.git $SRC/seeds
for f in $SRC/seeds/general_evaluation/jpg/* ; do
  s=$(sha1sum "$f" | awk '{print $1}')
  cp $f $SRC/corpus/$s
done

zip -j $OUT/fuzz-read-print-write_seed_corpus.zip $SRC/corpus/*

