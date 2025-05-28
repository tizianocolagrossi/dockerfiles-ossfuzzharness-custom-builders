#! /bin/bash
export CXXFLAGS=$(echo "$CXXFLAGS" | awk '{for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i}')
export CFLAGS=$(echo "$CFLAGS" | awk '{for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i}')

$CXX $CXXFLAGS -fsanitize=address  \
        -pthread -m64 -Wa,--noexecstack -Qunused-arguments -Wall -O3 -L. $SRC/harness.cpp -ldl -pthread -o $OUT/test 


cp $(ldd $OUT/test | cut -d" " -f3) $OUT
