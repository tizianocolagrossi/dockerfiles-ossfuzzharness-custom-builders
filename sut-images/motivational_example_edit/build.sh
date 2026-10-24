#!/bin/bash -eu

export PKG_CONFIG="`which pkg-config` --static"
# export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

cd /src/example/

$CC -O0 ./example.c -o ex_editO0
$CC -O1 ./example.c -o ex_editO1
$CC -O2 ./example.c -o ex_editO2