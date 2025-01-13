#!/bin/bash -eu
unset AFL_USE_UBSAN
pushd $SRC/bison-3.3
make clean || echo "make clean not runned correctly"
./configure
make -j $(nproc)
cp $SRC/bison-3.3/src/bison /out/

make clean
popd
