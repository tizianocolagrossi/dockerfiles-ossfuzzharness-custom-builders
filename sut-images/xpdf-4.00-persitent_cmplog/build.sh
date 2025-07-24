#!/bin/bash -eu
export AFL_LLVM_CMPLOG=1
cd $SRC/xpdf-4.00

#replace CMakelist with edited for esporting lib
rm ./xpdf/CMakeLists.txt
cp $SRC/CMakeLists.txt.xpdf ./xpdf/CMakeLists.txt
cp $SRC/fuzz_pdfload.cc ./xpdf/fuzz_pdfload.cc

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
cp $(ldd $OUT/fuzz_pdfload | cut -d" " -f3) $OUT