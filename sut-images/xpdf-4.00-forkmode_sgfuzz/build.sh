#!/bin/bash -eu

cd $SRC/xpdf-4.00

# replace with harness for libfuzzer
rm $SRC/xpdf-4.00/xpdf/pdftotext.cc
mv $SRC/pdftotext.cc $SRC/xpdf-4.00/xpdf/pdftotext.cc

rm $SRC/xpdf-4.00/xpdf/CMakeLists.txt
mv $SRC/CMakeLists.txt $SRC/xpdf-4.00/xpdf/CMakeLists.txt

echo "tag" > filter.txt
echo "state" >> filter.txt
echo "type" >> filter.txt
python3 /src/SGFuzz/sanitizer/State_machine_instrument.py . -b filter.txt


mkdir build
cd build
cmake -DCMAKE_CXX_FLAGS="$CXXFLAGS" ..
make -j

find ./xpdf -type f -executable -exec cp "{}" /out/ \;
cp $(ldd $OUT/pdftotext | cut -d" " -f3) $OUT