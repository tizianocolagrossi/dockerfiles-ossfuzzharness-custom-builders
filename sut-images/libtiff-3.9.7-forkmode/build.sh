#!/bin/bash -eu

cd $SRC/libtiff-Release-v3-9-7

./autogen.sh 
./configure --disable-shared
make -j 

cp tools/tiffsplit /out/tiffsplit
make clean 