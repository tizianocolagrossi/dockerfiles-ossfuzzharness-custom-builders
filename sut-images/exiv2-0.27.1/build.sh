
cd $SRC/exiv2
mkdir build
cd build

cmake .. -G "Unix Makefiles"
cmake --build .

cp bin/* /out/

ldd bin/exiv2

cd ..
rm -rf build 