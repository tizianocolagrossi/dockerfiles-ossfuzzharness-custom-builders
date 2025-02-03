#!/bin/bash -eu

cd $SRC/libtiff-Release-v3-9-7

export AFL_LLVM_CMPLOG=1
./autogen.sh 
./configure --disable-shared
make -j 

cp tools/tiffsplit /out/tiffsplit.cmplog
make clean 
touch $OUT/afl_cmplog.txt
unset AFL_LLVM_CMPLOG

./autogen.sh 
./configure --disable-shared
make -j 

cp tools/tiffsplit /out/tiffsplit
make clean 