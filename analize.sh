#! /bin/bash

# usage analyze.sh fuzzer_campaign_out fuzzer_analysis_build

if [ "$#" -ne 2 ]
then
  echo "USAGE: $0 <fuzzer-out-dir> <fuzzer-analysis-build>"
  exit 1
fi

FUZZ_OUT=$1

FUZZER_BUILD_ANALYSIS=$(realpath $2)


FUZZER=$(basename $FUZZER_BUILD_ANALYSIS)
ANALYSIS_BUILD=$(dirname $FUZZER_BUILD_ANALYSIS)

docker run -it --rm -v $FUZZ_OUT:/fuzz_out -v $ANALYSIS_BUILD:/out -e FUZZING_ENGINE=libafl -t oss-base-analysis analyze $FUZZER
