#!/bin/bash -eu

cd $SRC/ncurses-6.1
export AFL_LLVM_CMPLOG=1
./configure --disable-shared
make -j
# Note: infotocap is actually binary tic, the name infotocap should not be changed. 
# This is like busybox, which functionality is determined by its binary name
cp progs/tic /out/infotocap.cmplog
make clean 
touch $OUT/afl_cmplog.txt
unset AFL_LLVM_CMPLOG

./configure --disable-shared
make -j
# Note: infotocap is actually binary tic, the name infotocap should not be changed. 
# This is like busybox, which functionality is determined by its binary name
cp progs/tic /out/infotocap 
cp $(ldd $OUT/infotocap | cut -d" " -f3) $OUT