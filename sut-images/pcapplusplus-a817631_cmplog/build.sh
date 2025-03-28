#!/bin/bash -eu
#
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

# taken at ossfuzz commit 0990a14

# CFLAGS="-ldbus-1 $CFLAGS"
# CXXFLAGS="-ldbus-1 $CXXFLAGS"

pushd $SRC/PcapPlusPlus
git reset --hard
git fetch --all -pP
git checkout a817631
git apply $SRC/fuzzers_makepile.patch
popd

pushd $SRC/libpcap

popd

# pkg-config --libs --cflags dbus-1

export AFL_LLVM_CMPLOG=1

# Build libpcap
cd $SRC/libpcap/
./autogen.sh
./configure --enable-shared=no
make -j$(nproc)

# Build PcapPlusPlus linking statically against the built libpcap
cd $SRC/PcapPlusPlus
./configure-fuzzing.sh --libpcap-static-lib-dir $SRC/libpcap/
make clean
make fuzzers -j$(nproc) 

touch $OUT/afl_cmplog.txt
unset AFL_LLVM_CMPLOG

# Copy target and options
cp $SRC/PcapPlusPlus/Tests/Fuzzers/Bin/FuzzTarget $OUT/FuzzTarget.cmplog
cp $(ldd $OUT/FuzzTarget.cmplog | cut -d" " -f3) $OUT
cp $SRC/default.options $OUT/FuzzTarget.options

# Build libpcap
cd $SRC/libpcap/
make clean
./autogen.sh
./configure --enable-shared=no
make -j$(nproc)

# Build PcapPlusPlus linking statically against the built libpcap
cd $SRC/PcapPlusPlus
./configure-fuzzing.sh --libpcap-static-lib-dir $SRC/libpcap/
make clean
make fuzzers -j$(nproc) 

# Copy target and options
cp $SRC/PcapPlusPlus/Tests/Fuzzers/Bin/FuzzTarget $OUT/FuzzTarget
cp $(ldd $OUT/FuzzTarget | cut -d" " -f3) $OUT
cp $SRC/default.options $OUT/FuzzTarget.options




# Copy corpora
cd $SRC/tcpdump
zip -jr FuzzTarget_seed_corpus.zip tests/*.pcap
cp FuzzTarget_seed_corpus.zip $OUT/
