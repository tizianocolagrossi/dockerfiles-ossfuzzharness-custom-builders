#! /bin/bash

if [ "$#" -ne 2 ]
then
  echo "USAGE: $0 <fuzzer-out-dir> <fuzzer-deduplication-used"
  exit 1
fi

FUZZ_OUT=$1

FUZZER_BUILD_DEDUP=$(realpath $2)

docker run -it --rm --shm-size=1gb -v $FUZZ_OUT:/out -v $FUZZER_BUILD_DEDUP:/in -e OUTUID=$(id -u) -e OUTGID=$(id -g) -t osvaldo/manual-analysis /bin/bash