#!/bin/bash -eu
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

export AFL_LLVM_CMPLOG=1
mkdir $WORK/build_cmplog
mkdir $WORK/build

cd $WORK/build_cmplog
cmake -G Ninja -DBUILD_TESTING=false $SRC/bloaty
ninja -j$(nproc)
cp fuzz_target $OUT/fuzz_target.cmplog

touch $OUT/afl_cmplog.txt
unset AFL_LLVM_CMPLOG


cd $WORK/build
cmake -G Ninja -DBUILD_TESTING=false $SRC/bloaty
ninja -j$(nproc)
cp fuzz_target $OUT/fuzz_target
cp $(ldd $OUT/fuzz_target | cut -d" " -f3) $OUT

zip -j $OUT/fuzz_target_seed_corpus.zip $SRC/bloaty/tests/testdata/fuzz_corpus/*