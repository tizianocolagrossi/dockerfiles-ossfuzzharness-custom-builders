#! /bin/bash
export CXXFLAGS=$(echo "$CXXFLAGS" | awk '{for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i}')
export CFLAGS=$(echo "$CFLAGS" | awk '{for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i}')

$CXX $CXXFLAGS -fsanitize=address -Wl,--whole-archive /usr/lib/libhfcommon.a /usr/lib/libhfnetdriver.a -Wl,--no-whole-archive \
        -pthread -m64 -Wa,--noexecstack -Qunused-arguments -Wall -O3 -L. $SRC/harness.cpp -ldl -pthread -o $OUT/test 

# $CXX $CXXFLAGS -fsanitize=address -Wl,--whole-archive /usr/lib/libhfcommon.a /usr/lib/libhfnetdriver.a -Wl,--no-whole-archive \
#         -pthread -m64 -Wa,--noexecstack -Qunused-arguments -Wall -O3 -L. $SRC/harness_fork.cpp -ldl -pthread -o $OUT/test_fork

$CXX $CXXFLAGS -fsanitize=address -Wl,--whole-archive /usr/lib/libhfcommon.a /usr/lib/libhfnetdriver.a -Wl,--no-whole-archive \
        -pthread -m64 -Wa,--noexecstack -Qunused-arguments -Wall -O3 -L. $SRC/harness_while.cpp -ldl -pthread -o $OUT/test_while

cp $(ldd $OUT/test | cut -d" " -f3) $OUT
