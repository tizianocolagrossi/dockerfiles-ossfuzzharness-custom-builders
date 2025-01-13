#!/bin/bash -eu
export AFL_LLVM_CMPLOG=1
cd $SRC/xpdf-4.00
mkdir build
cd build
cmake -DCMAKE_CXX_FLAGS="$CXXFLAGS" ..
make -j
find ./xpdf -type f -executable -exec mv "{}" "{}".cmplog \;
find ./xpdf -type f -executable -exec cp "{}" /out/ \;

cd ..
rm -rf build 

touch $OUT/afl_cmplog.txt
unset AFL_LLVM_CMPLOG

mkdir build
cd build
cmake -DCMAKE_CXX_FLAGS="$CXXFLAGS" ..
make -j
find ./xpdf -type f -executable -exec cp "{}" /out/ \;
