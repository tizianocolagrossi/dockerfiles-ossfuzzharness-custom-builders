#! /bin/bash -eux

cd /src/SGFuzz

echo "Building sfuzzer driver..."
for f in ./*.cpp; do
  clang++ -g -fPIC -O2 -std=c++11 $f -c &
done
wait
rm -f /usr/lib/libsFuzzer.a
ar r /usr/lib/libsFuzzer.a Fuzzer*.o
rm -f Fuzzer*.o

rm -r /usr/lib/libFuzzingEngine.a 
ln -s /usr/lib/libsFuzzer.a /usr/lib/libFuzzingEngine.a