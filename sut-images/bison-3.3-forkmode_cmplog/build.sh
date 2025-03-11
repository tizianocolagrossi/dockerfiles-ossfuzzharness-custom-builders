#!/bin/bash -eu

unset AFL_USE_UBSAN

export AFL_LLVM_CMPLOG=1

pushd $SRC/bison-3.3
make clean || echo "make clean not runned correctly"
./configure
make -j $(nproc)
cp $SRC/bison-3.3/src/bison /out/bison.cmplog

make clean
touch $OUT/afl_cmplog.txt
popd
unset AFL_LLVM_CMPLOG

pushd $SRC/bison-3.3
make clean || echo "make clean not runned correctly"
./configure
make -j $(nproc)
cp $SRC/bison-3.3/src/bison /out/
cp $(ldd $OUT/bison | cut -d" " -f3) $OUT

make clean
popd


