
cd $SRC/exiv2
mkdir build
cd build

cmake -G "Unix Makefiles" -DBUILD_SHARED_LIBS=Off -DEXTRA_COMPILE_FLAGS="$CXXFLAGS" ..
make -j $(nproc)

cp bin/* /out/

ldd bin/exiv2

cd ..
rm -rf build 

# export AFL_LLVM_CMPLOG=1

# cd $SRC/exiv2
# mkdir build
# cd build

# cmake -G "Unix Makefiles" -DBUILD_SHARED_LIBS=Off -DEXTRA_COMPILE_FLAGS="$CXXFLAGS" ..
# make -j $(nproc)

# cp bin/exiv2 /out/exiv2.cmplog

# cd ..
# rm -rf build 

# touch $OUT/afl_cmplog.txt
# unset AFL_LLVM_CMPLOG

