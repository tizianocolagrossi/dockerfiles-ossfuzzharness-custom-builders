#!/bin/bash -eu

cd $SRC/ncurses-6.1
./configure --disable-shared
make -j
# Note: infotocap is actually binary tic, the name infotocap should not be changed. 
# This is like busybox, which functionality is determined by its binary name
cp progs/tic /out/infotocap 