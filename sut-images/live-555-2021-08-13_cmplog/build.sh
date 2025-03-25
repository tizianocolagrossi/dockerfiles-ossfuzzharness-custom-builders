#! /bin/bash

export C_COMPILER=$CC 
export CPLUSPLUS_COMPILER=$CXX

export CXXFLAGS=$(echo "$CXXFLAGS" | awk '{for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i}')
export CFLAGS=$(echo "$CFLAGS" | awk '{for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i}')
export CXXFLAGS="${CXXFLAGS//-fsanitize=fuzzer/-fsanitize=fuzzer-no-link}"
export CFLAGS="${CFLAGS//-fsanitize=fuzzer/-fsanitize=fuzzer-no-link}"

export CXXFLAGS="${CXXFLAGS//-gline-tables-only }"
export CXXFLAGS="${CXXFLAGS//-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION/ }"

export CFLAGS="${CFLAGS//-gline-tables-only/ }"
export CFLAGS="${CFLAGS//-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION/ }"




# ASAN_OPTIONS=alloc_dealloc_mismatch=0 ./testOnDemandRTSPServer -close_fd_mask=3 -detect_leaks=0 -dict=rtsp.dict -only_ascii=1 /in-rtsp/

export AFL_LLVM_CMPLOG=1
cp -r live live555
pushd live555

patch -p1 < $SRC/fuzzing.patch
sed -i "s/int main(/extern \"C\" int HonggfuzzNetDriver_main(/g" testProgs/testOnDemandRTSPServer.cpp 
./genMakefiles linux-no-openssl 

make C_COMPILER=$CC CPLUSPLUS_COMPILER=$CXX CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LINK="$CXX $CXXFLAGS -o " all || \
export CXXFLAGS="${CXXFLAGS//-fsanitize=fuzzer-no-link/-fsanitize=fuzzer}" && \
export CFLAGS="${CFLAGS//-fsanitize=fuzzer-no-link/-fsanitize=fuzzer}" && \
cd testProgs; $CXX $CXXFLAGS -o $OUT/testOnDemandRTSPServer.cmplog -L.  testOnDemandRTSPServer.o announceURL.o ../liveMedia/libliveMedia.a ../groupsock/libgroupsock.a ../BasicUsageEnvironment/libBasicUsageEnvironment.a ../UsageEnvironment/libUsageEnvironment.a -Wl,--whole-archive /usr/lib/libhfcommon.a /usr/lib/libhfnetdriver.a -Wl,--no-whole-archive

touch $OUT/afl_cmplog.txt
unset AFL_LLVM_CMPLOG

popd 

rm -rf live555
cp -r live live555

pushd live555
export CXXFLAGS="${CXXFLAGS//-fsanitize=fuzzer/-fsanitize=fuzzer-no-link}"
export CFLAGS="${CFLAGS//-fsanitize=fuzzer/-fsanitize=fuzzer-no-link}"

patch -p1 < $SRC/fuzzing.patch
sed -i "s/int main(/extern \"C\" int HonggfuzzNetDriver_main(/g" testProgs/testOnDemandRTSPServer.cpp 
./genMakefiles linux-no-openssl 

make C_COMPILER=$CC CPLUSPLUS_COMPILER=$CXX CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LINK="$CXX $CXXFLAGS -o " all || \
export CXXFLAGS="${CXXFLAGS//-fsanitize=fuzzer-no-link/-fsanitize=fuzzer}" && \
export CFLAGS="${CFLAGS//-fsanitize=fuzzer-no-link/-fsanitize=fuzzer}" && \
cd testProgs; $CXX $CXXFLAGS -o $OUT/testOnDemandRTSPServer -L.  testOnDemandRTSPServer.o announceURL.o ../liveMedia/libliveMedia.a ../groupsock/libgroupsock.a ../BasicUsageEnvironment/libBasicUsageEnvironment.a ../UsageEnvironment/libUsageEnvironment.a -Wl,--whole-archive /usr/lib/libhfcommon.a /usr/lib/libhfnetdriver.a -Wl,--no-whole-archive

popd 

cp $(ldd $OUT/testOnDemandRTSPServer | cut -d" " -f3) $OUT

cp $SRC/testOnDemandRTSPServer_seed_corpus.zip $OUT
cp $SRC/*.dict $OUT/
cp $SRC/blocked_variables.txt $OUT/