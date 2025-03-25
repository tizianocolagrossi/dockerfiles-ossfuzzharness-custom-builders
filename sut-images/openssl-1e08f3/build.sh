#! /bin/bash

cd $SRC/openssl

sed -i "s/ main/ HonggfuzzNetDriver_main/g" apps/openssl.c

export CXXFLAGS=$(echo "$CXXFLAGS" | awk '{for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i}')
export CFLAGS=$(echo "$CFLAGS" | awk '{for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i}')
export CXXFLAGS="${CXXFLAGS//-fsanitize=fuzzer/-fsanitize=fuzzer-no-link}"
export CFLAGS="${CFLAGS//-fsanitize=fuzzer/-fsanitize=fuzzer-no-link}"

./config no-shared
make build_generated

export CXXFLAGS="${CXXFLAGS//-fsanitize=fuzzer-no-link/-fsanitize=fuzzer}"
export CFLAGS="${CFLAGS//-fsanitize=fuzzer-no-link/-fsanitize=fuzzer}"
make apps/openssl || $CXX $CXXFLAGS -Wl,--whole-archive /usr/lib/libhfcommon.a /usr/lib/libhfnetdriver.a -Wl,--no-whole-archive \
        -pthread -m64 -Wa,--noexecstack -Qunused-arguments -Wall -O3 -L. \
        apps/lib/openssl-bin-cmp_mock_srv.o \
        apps/openssl-bin-asn1parse.o apps/openssl-bin-ca.o \
        apps/openssl-bin-ciphers.o apps/openssl-bin-cmp.o \
        apps/openssl-bin-cms.o apps/openssl-bin-crl.o \
        apps/openssl-bin-crl2pkcs7.o apps/openssl-bin-dgst.o \
        apps/openssl-bin-dhparam.o apps/openssl-bin-dsa.o \
        apps/openssl-bin-dsaparam.o apps/openssl-bin-ec.o \
        apps/openssl-bin-ecparam.o apps/openssl-bin-enc.o \
        apps/openssl-bin-engine.o apps/openssl-bin-errstr.o \
        apps/openssl-bin-fipsinstall.o apps/openssl-bin-gendsa.o \
        apps/openssl-bin-genpkey.o apps/openssl-bin-genrsa.o \
        apps/openssl-bin-info.o apps/openssl-bin-kdf.o \
        apps/openssl-bin-list.o apps/openssl-bin-mac.o \
        apps/openssl-bin-nseq.o apps/openssl-bin-ocsp.o \
        apps/openssl-bin-openssl.o apps/openssl-bin-passwd.o \
        apps/openssl-bin-pkcs12.o apps/openssl-bin-pkcs7.o \
        apps/openssl-bin-pkcs8.o apps/openssl-bin-pkey.o \
        apps/openssl-bin-pkeyparam.o apps/openssl-bin-pkeyutl.o \
        apps/openssl-bin-prime.o apps/openssl-bin-progs.o \
        apps/openssl-bin-rand.o apps/openssl-bin-rehash.o \
        apps/openssl-bin-req.o apps/openssl-bin-rsa.o \
        apps/openssl-bin-rsautl.o apps/openssl-bin-s_client.o \
        apps/openssl-bin-s_server.o apps/openssl-bin-s_time.o \
        apps/openssl-bin-sess_id.o apps/openssl-bin-smime.o \
        apps/openssl-bin-speed.o apps/openssl-bin-spkac.o \
        apps/openssl-bin-srp.o apps/openssl-bin-storeutl.o \
        apps/openssl-bin-ts.o apps/openssl-bin-verify.o \
        apps/openssl-bin-version.o apps/openssl-bin-x509.o \
        apps/libapps.a -lssl -lcrypto -ldl -pthread \
        -o $OUT/openssl 

cp $(ldd $OUT/openssl | cut -d" " -f3) $OUT

# Run command
# cd experiments/openssl && \
# ./apps/openssl -close_fd_mask=3 ../in-tls -- s_server -key ../key.pem -cert ../cert.pem -4 -no_anti_replay // for sgfuzz

cp $SRC/*.pem $OUT
cp $SRC/*.dict $OUT
cp $SRC/*.zip $OUT