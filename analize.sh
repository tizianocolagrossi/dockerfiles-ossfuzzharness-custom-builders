#! /bin/bash

# usage analyze.sh fuzzer_campaign_out fuzzer_analysis_build

# Usage function
usage() {
    echo "Usage: $0 [-c -s -m -a <sut args> ] -o <output_path>  <coverage-build_path> <deduplication-build_path>"
    echo "  -c    request code coverage data"
    echo "  -e    request enum coverage data"
    echo "  -m    multidesock enabled"
    echo "  -o    output directory"
    echo "  -a    sut args"
    echo "  <coverage-build_path> Path to the fuzzer used to collect coverage data"
    echo "  <deduplication-build_path> Path to the suzzer used to deduplicat crashes"
    exit 1
}

# Get the current user's UID
current_uid=$(id -u)

# Default values
coverage_profile_enabled=false
enum_profile_enabled=false
multidesock_enabled=false
output_dir=""
sut_args=""


# Parse options
while getopts "cemo:a:" opt; do
    case $opt in
        c) coverage_profile_enabled="true" ;;
        e) enum_profile_enabled="true" ;;
        m) multidesock_enabled="true" ;;
        o) output_dir="$OPTARG" ;;
        a) sut_args="$OPTARG" ;;
        *) usage ;;
    esac
done

# Shift processed options
shift $((OPTIND - 1))


# Remaining argument is the project path
if [[ $# -eq 2 ]]; then
  FUZZER_BUILD_ANALYSIS=$(realpath $1)
  FUZZER_BUILD_DEDUP=$(realpath $2)
else
    echo "Error: You must specify a project path."
    usage
fi

# Validate inputs
if [[ -z "$output_dir" ]]; then
    echo "Error: options (-o) is required."
    usage
fi

if [[ ! -e "$FUZZER_BUILD_ANALYSIS" ]]; then
    echo "Error: The specified project path does not exist: $FUZZER_BUILD_ANALYSIS"
    exit 1
fi


if [[ ! -e "$FUZZER_BUILD_DEDUP" ]]; then
    echo "Error: The specified project path does not exist : $FUZZER_BUILD_DEDUP"
    exit 1
fi


FUZZER=$(basename $FUZZER_BUILD_ANALYSIS)
ANALYSIS_BUILD=$(dirname $FUZZER_BUILD_ANALYSIS)
FUZZER_DEDUP=$(basename $FUZZER_BUILD_DEDUP)
DEDUP_BUILD=$(dirname $FUZZER_BUILD_DEDUP)

if [ $FUZZER_DEDUP -ne $FUZZER ] ; then 
  echo "Error fuzzer analysis and deduplication are different!"
  exit 1
fi

# Display selected options
echo "Code coverage requested: $coverage_profile_enabled"
echo "Enum coverage requested: $enum_profile_enabled"
echo "Output dir: $output_dir"
echo "SUT args: $sut_args"

echo "Fuzzer: $FUZZER"
echo "Fuzzer build for deduplication: $DEDUP_BUILD"
echo "Fuzzer build for coverage: $ANALYSIS_BUILD"
echo ""

docker run -it --rm --shm-size=1gb \
  -v $output_dir:/fuzz_out \
  -v $DEDUP_BUILD:/dedup_build \
  -v $ANALYSIS_BUILD:/out \
  -e FUZZ_OUT_REAL_PATH=$output_dir \
  -e SUT_ARGS="$sut_args" \
  -e COVERAGE_PROFILE=$coverage_profile_enabled  \
  -e ENUMERATION_PROFILE=$enum_profile_enabled  \
  -e MULTIDESOCK=$multidesock_enabled \
  -e OUTUID=$(id -u) -e OUTGID=$(id -g) \
  -t osvaldo/oss-base-analysis analyze $FUZZER
