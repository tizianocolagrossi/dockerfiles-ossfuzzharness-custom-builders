#!/bin/bash -eu

cd $SRC/xpdf-4.00
mkdir build
cd build
cmake -DCMAKE_CXX_FLAGS="$CXXFLAGS" ..
make -j

find ./xpdf -type f -executable -exec cp "{}" /out/ \;
