
cd $SRC/exiv2
mkdir build
cd build
cmake -G "Unix Makefiles" -DBUILD_SHARED_LIBS=Off -DEXTRA_COMPILE_FLAGS="$CXXFLAGS" ..
make -j $(nproc)
cp bin/* /out/

ldd bin/exiv2
cp $(ldd $OUT/exiv2 | cut -d" " -f3) $OUT

cd ..
rm -rf build 


