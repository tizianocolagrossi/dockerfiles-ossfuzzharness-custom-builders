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

docker run -it --rm -v $FUZZ_OUT:/fuzz_out -v $DEDUP_BUILD:/dedup_build -v $ANALYSIS_BUILD:/out -e FUZZ_OUT_REAL_PATH=$FUZZ_OUT -e FUZZING_ENGINE=libafl -t oss-base-analysis analyze $FUZZER

# for d in /home/tiziano/Documents/new-docker-run/new_evluation-v0.2.6tmp3/xpdf-v4.00/regression_v4.00/* ; do ./analize.sh $d /home/tiziano/sut-docker/v0.2.6tmp6/xpdf-v4.00/analysis/fuzz_pdfload /home/tiziano/sut-docker/v0.2.6tmp6/xpdf-v4.00/enumetricbb++/fuzz_pdfload ; done;
# for d in /home/tiziano/Documents/new-docker-run/new_evluation-v0.2.6tmp3/xpdf-v4.00/regression_v4.01/* ; do ./analize.sh $d /home/tiziano/sut-docker/v0.2.6tmp6/xpdf-v4.01/analysis/fuzz_pdfload /home/tiziano/sut-docker/v0.2.6tmp6/xpdf-v4.01/enumetricbb++/fuzz_pdfload ; done;
# for d in /home/tiziano/Documents/new-docker-run/new_evluation-v0.2.6tmp3/xpdf-v4.00/regression_v4.02/* ; do ./analize.sh $d /home/tiziano/sut-docker/v0.2.6tmp6/xpdf-v4.02/analysis/fuzz_pdfload /home/tiziano/sut-docker/v0.2.6tmp6/xpdf-v4.02/enumetricbb++/fuzz_pdfload ; done;
# for d in /home/tiziano/Documents/new-docker-run/new_evluation-v0.2.6tmp3/xpdf-v4.00/regression_v4.03/* ; do ./analize.sh $d /home/tiziano/sut-docker/v0.2.6tmp6/xpdf-v4.03/analysis/fuzz_pdfload /home/tiziano/sut-docker/v0.2.6tmp6/xpdf-v4.03/enumetricbb++/fuzz_pdfload ; done;
# for d in /home/tiziano/Documents/new-docker-run/new_evluation-v0.2.6tmp3/xpdf-v4.00/regression_v4.04/* ; do ./analize.sh $d /home/tiziano/sut-docker/v0.2.6tmp6/xpdf-v4.04/analysis/fuzz_pdfload /home/tiziano/sut-docker/v0.2.6tmp6/xpdf-v4.04/enumetricbb++/fuzz_pdfload ; done;
# for d in /home/tiziano/Documents/new-docker-run/new_evluation-v0.2.6tmp3/xpdf-v4.00/regression_v4.05/* ; do ./analize.sh $d /home/tiziano/sut-docker/v0.2.6tmp6/xpdf-v4.05/analysis/fuzz_pdfload /home/tiziano/sut-docker/v0.2.6tmp6/xpdf-v4.05/enumetricbb++/fuzz_pdfload ; done;
