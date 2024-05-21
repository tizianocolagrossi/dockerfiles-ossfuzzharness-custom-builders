#! /bin/bash

# usage analyze.sh fuzzer_campaign_out fuzzer_analysis_build

if [ "$#" -ne 3 ]
then
  echo "USAGE: $0 <fuzzer-out-dir> <fuzzer-analysis-build> <fuzzer-deduplication-build-w-sanitizers>"
  exit 1
fi

FUZZ_OUT=$1

FUZZER_BUILD_ANALYSIS=$(realpath $2)

FUZZER_BUILD_DEDUP=$(realpath $3)


FUZZER=$(basename $FUZZER_BUILD_ANALYSIS)
ANALYSIS_BUILD=$(dirname $FUZZER_BUILD_ANALYSIS)
FUZZER_DEDUP=$(basename $FUZZER_BUILD_DEDUP)
DEDUP_BUILD=$(dirname $FUZZER_BUILD_DEDUP)

if [ $FUZZER_DEDUP -ne $FUZZER ] ; then 
  echo "Error fuzzer analysis and deduplication are different!"
  exit 1
fi

docker run -it --rm -v $FUZZ_OUT:/fuzz_out -v $DEDUP_BUILD:/dedup_build -v $ANALYSIS_BUILD:/out -e FUZZING_ENGINE=libafl -t oss-base-analysis analyze $FUZZER
