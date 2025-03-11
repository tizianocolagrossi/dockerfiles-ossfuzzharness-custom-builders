#!/bin/bash -eu

cd $SRC/libtiff-Release-v3-9-7

./autogen.sh 
./configure --disable-shared
make -j 

cp tools/tiffsplit /out/tiffsplit
cp $(ldd $OUT/tiffsplit | cut -d" " -f3) $OUT
make clean 