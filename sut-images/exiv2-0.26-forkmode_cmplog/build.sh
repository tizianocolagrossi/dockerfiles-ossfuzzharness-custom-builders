#!/bin/bash -eu
export AFL_LLVM_CMPLOG=1
cd $SRC/exiv2-0.26
mkdir build
cd build
cmake -DEXIV2_ENABLE_SHARED=OFF ..
make -j
cp bin/exiv2 /out/exiv2.cmplog

cd ..
rm -rf build 

touch $OUT/afl_cmplog.txt
unset AFL_LLVM_CMPLOG

mkdir build
cd build
cmake -DEXIV2_ENABLE_SHARED=OFF ..
make -j
cp bin/exiv2 /out/exiv2
