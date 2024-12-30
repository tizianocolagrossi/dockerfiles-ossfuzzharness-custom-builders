#!/bin/bash -eu

unset AFL_USE_UBSAN

pushd $SRC/bison-3.3
make clean || echo "make clean not runned correctly"
./configure
make -j $(nproc)
cp $SRC/bison-3.3/src/bison /out/

make clean
popd


export AFL_LLVM_CMPLOG=1

pushd $SRC/bison-3.3
make clean || echo "make clean not runned correctly"
./configure
make -j $(nproc)
cp $SRC/bison-3.3/src/bison /out/bison.cmplog

make clean
popd

touch $OUT/afl_cmplog.txt
unset AFL_LLVM_CMPLOG