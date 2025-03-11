#!/bin/bash -eu

cd $SRC/exiv2-0.26
mkdir build
cd build
cmake -DEXIV2_ENABLE_SHARED=OFF ..
make -j
cp bin/exiv2 /out/exiv2
