#! /bin/bash

cd $SRC/openssl

# sed -i "s/ main/ HonggfuzzNetDriver_main/g" apps/openssl.c

# disable eventual fork
# sed -i 's|if (fork()) {|if (0) {|' apps/speed.c 
# sed -i 's|switch (fpid = fork()) {|switch (fpid = 0) {|' apps/lib/http_server.c

export CXXFLAGS=$(echo "$CXXFLAGS" | awk '{for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i}')
export CFLAGS=$(echo "$CFLAGS" | awk '{for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i}')
export CXXFLAGS="${CXXFLAGS//-fsanitize=fuzzer/-fsanitize=fuzzer-no-link}"
export CFLAGS="${CFLAGS//-fsanitize=fuzzer/-fsanitize=fuzzer-no-link}"

export AFL_LLVM_CMPLOG=1

./config no-shared
make build_generated

export CXXFLAGS="${CXXFLAGS//-fsanitize=fuzzer-no-link/-fsanitize=fuzzer}"
export CFLAGS="${CFLAGS//-fsanitize=fuzzer-no-link/-fsanitize=fuzzer}"
make apps/openssl

cp apps/openssl $OUT/openssl.cmplog

make clean

unset AFL_LLVM_CMPLOG
export CXXFLAGS="${CXXFLAGS//-fsanitize=fuzzer/-fsanitize=fuzzer-no-link}"
export CFLAGS="${CFLAGS//-fsanitize=fuzzer/-fsanitize=fuzzer-no-link}"
./config no-shared
make build_generated

export CXXFLAGS="${CXXFLAGS//-fsanitize=fuzzer-no-link/-fsanitize=fuzzer}"
export CFLAGS="${CFLAGS//-fsanitize=fuzzer-no-link/-fsanitize=fuzzer}"
make apps/openssl

cp apps/openssl $OUT/openssl

cp $(ldd $OUT/openssl | cut -d" " -f3) $OUT


# Run command
# cd experiments/openssl && \
# ./apps/openssl -close_fd_mask=3 ../in-tls -- s_server -key ../key.pem -cert ../cert.pem -4 -no_anti_replay // for sgfuzz

cp $SRC/*.pem $OUT
cp $SRC/*.dict $OUT
cp $SRC/*.zip $OUT