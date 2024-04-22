#! /bin/bash
ENUMETRIC_VERSION=v0.2.3
LIBAFL_BRANCH=OnDiskCSVMonitor

cd /src/LibAFL
git checkout $LIBAFL_BRANCH

cd /src/Enumetric
git checkout tags/$ENUMETRIC_VERSION
mkdir build
cd build
cmake ..
make

##todo change please!
mkdir -p /home/tiziano/Documents/Enumetric/build/lib/
ln -s /src/Enumetric/build/lib/libEnumetric.so /home/tiziano/Documents/Enumetric/build/lib/
ln -s /src/Enumetric/build/lib/libFED.so  /home/tiziano/Documents/Enumetric/build/lib/

cd /src/Enumetric/enumetric_fuzzer
/root/.cargo/bin/cargo build --release

cp -r /src/Enumetric/enumetric_fuzzer/target/release/* /usr/local/bin


