#!/bin/bash

COVERAGE_TAG='code-enum-cov'
DEDUPLICATION_TAG='deduplication'
ARGS_TAG='args'

# CPU_RANGE="64-118"
CPU_RANGE="0-4"

OUTPUTS_DIR=/home/tiziano/outputs/
ANALIZE_SCRIPT_PATH=/home/tiziano/Documents/enumetric-Research/dockerfiles-ossfuzzharness-custom-builders/analize.sh

DUMMY=1
if [ -n "$1" ] ; then
    if [ "$1" == "--no-dummy" ] ; then
        DUMMY=0
    fi
fi

# Declare the associative array
declare -A analysis_program
declare -A analysis_program_args

BASE_TOOLS_PATH=~/sut-docker/debug-aflppdouble-v0.2.7

# Populate structure (manual entries)
FUZZER=fuzz_pdfload
SUT=xpdf-4.00-persitent_cmplog
SUTNAME=xpdf-4.00-persitent
analysis_program["$SUTNAME:$COVERAGE_TAG"]="$BASE_TOOLS_PATH/$SUT/code-enum-cov/$FUZZER"
analysis_program["$SUTNAME:$DEDUPLICATION_TAG"]="$BASE_TOOLS_PATH/$SUT/aflpp/$FUZZER"
analysis_program_args["$SUTNAME"]="@@"

FUZZER=pdftotext
SUT=xpdf-4.00-forkmode_cmplog
SUTNAME=xpdf-4.00-forkmode
analysis_program["$SUTNAME:$COVERAGE_TAG"]="$BASE_TOOLS_PATH/$SUT/code-enum-cov/$FUZZER"
analysis_program["$SUTNAME:$DEDUPLICATION_TAG"]="$BASE_TOOLS_PATH/$SUT/aflpp/$FUZZER"
analysis_program_args["$SUTNAME"]="@@ /dev/null"

FUZZER=FuzzTarget
SUT=pcapplusplus-a817631_cmplog
SUTNAME=pcapplusplus-a817631
analysis_program["$SUTNAME:$COVERAGE_TAG"]="$BASE_TOOLS_PATH/$SUT/code-enum-cov/$FUZZER"
analysis_program["$SUTNAME:$DEDUPLICATION_TAG"]="$BASE_TOOLS_PATH/$SUT/aflpp/$FUZZER"
analysis_program_args["$SUTNAME"]="@@"

FUZZER=infotocap
SUT=ncurses-6.1-forkmode_cmplog
SUTNAME=ncurses-6.1
analysis_program["$SUTNAME:$COVERAGE_TAG"]="$BASE_TOOLS_PATH/$SUT/code-enum-cov/$FUZZER"
analysis_program["$SUTNAME:$DEDUPLICATION_TAG"]="$BASE_TOOLS_PATH/$SUT/aflpp/$FUZZER"
analysis_program_args["$SUTNAME"]="-o /dev/null @@"

FUZZER=xml
SUT=libxml2-v2.9.2-persistent_cmplog
SUTNAME=libxml2-v2.9.2
analysis_program["$SUTNAME:$COVERAGE_TAG"]="$BASE_TOOLS_PATH/$SUT/code-enum-cov/$FUZZER"
analysis_program["$SUTNAME:$DEDUPLICATION_TAG"]="$BASE_TOOLS_PATH/$SUT/aflpp/$FUZZER"
analysis_program_args["$SUTNAME"]="@@"

FUZZER=tiffsplit
SUT=libtiff-3.9.7-forkmode_cmplog
SUTNAME=libtiff-3.9.7
analysis_program["$SUTNAME:$COVERAGE_TAG"]="$BASE_TOOLS_PATH/$SUT/code-enum-cov/$FUZZER"
analysis_program["$SUTNAME:$DEDUPLICATION_TAG"]="$BASE_TOOLS_PATH/$SUT/aflpp/$FUZZER"
analysis_program_args["$SUTNAME"]="@@"

FUZZER=gm
SUT=graphicsmagick-1.3.31-forkmode_cmplog
SUTNAME=graphicsmagick-1.3.31
analysis_program["$SUTNAME:$COVERAGE_TAG"]="$BASE_TOOLS_PATH/$SUT/code-enum-cov/$FUZZER"
analysis_program["$SUTNAME:$DEDUPLICATION_TAG"]="$BASE_TOOLS_PATH/$SUT/aflpp/$FUZZER"
analysis_program_args["$SUTNAME"]="convert @@ /dev/null"

FUZZER=exiv2
SUT=exiv2-0.26-forkmode_cmplog
SUTNAME=exiv2-0.26
analysis_program["$SUTNAME:$COVERAGE_TAG"]="$BASE_TOOLS_PATH/$SUT/code-enum-cov/$FUZZER"
analysis_program["$SUTNAME:$DEDUPLICATION_TAG"]="$BASE_TOOLS_PATH/$SUT/aflpp/$FUZZER"
analysis_program_args["$SUTNAME"]="@@"

FUZZER=curl_fuzzer
SUT=curl-aab3a7_cmplog
SUTNAME=curl-aab3a7
analysis_program["$SUTNAME:$COVERAGE_TAG"]="$BASE_TOOLS_PATH/$SUT/code-enum-cov/$FUZZER"
analysis_program["$SUTNAME:$DEDUPLICATION_TAG"]="$BASE_TOOLS_PATH/$SUT/aflpp/$FUZZER"
analysis_program_args["$SUTNAME"]="@@"

FUZZER=fuzz_target
SUT=bloaty-2020-05-25_cmplog
SUTNAME=bloaty-2020-05-25
analysis_program["$SUTNAME:$COVERAGE_TAG"]="$BASE_TOOLS_PATH/$SUT/code-enum-cov/$FUZZER"
analysis_program["$SUTNAME:$DEDUPLICATION_TAG"]="$BASE_TOOLS_PATH/$SUT/aflpp/$FUZZER"
analysis_program_args["$SUTNAME"]="@@"

FUZZER=bison
SUT=bison-3.3-forkmode_cmplog
SUTNAME=bison-3.3
analysis_program["$SUTNAME:$COVERAGE_TAG"]="$BASE_TOOLS_PATH/$SUT/code-enum-cov/$FUZZER"
analysis_program["$SUTNAME:$DEDUPLICATION_TAG"]="$BASE_TOOLS_PATH/$SUT/aflpp/$FUZZER"
analysis_program_args["$SUTNAME"]="@@ -o /dev/null"


# Function: Validate all tool paths
validate_tools() {
    local error_found=0
    echo "Validating tool paths..."

    for key in "${!analysis_program[@]}"; do
        local tool_path="${analysis_program[$key]}"
        if [[ ! -x "$tool_path" ]]; then
            echo "❌ Invalid or non-executable tool for [$key]: $tool_path"
            error_found=1
        else
            echo "✅ OK [$key] -> $tool_path"
        fi
    done

    if [[ $error_found -ne 0 ]]; then
        echo "ERROR: One or more tool paths are invalid. Exiting."
        exit 1
    fi
}


# Validate at startup
validate_tools

# Extract unique SUTs into an array
declare -A seen_suts
sut_list=()

for key in "${!analysis_program[@]}"; do
    IFS=":" read -r sut _ <<< "$key"
    if [[ -z "${seen_suts[$sut]}" ]]; then
        seen_suts["$sut"]=1
        sut_list+=("$sut")
    fi
done





echo "Unique SUTs:"
for sut in "${sut_list[@]}"; do
    echo "- $sut"
    for fuzz_out_dir in $OUTPUTS_DIR*$sut*; do 
        if [ ! -d "$fuzz_out_dir" ]; then
            # echo "$fuzz_out_dir not exist"
            break
        fi
        echo "Found output"
        coverage_build="${analysis_program["$sut:$COVERAGE_TAG"]}"
        deduplication_build="${analysis_program["$sut:$DEDUPLICATION_TAG"]}"
        args="${analysis_program_args["$sut"]}"
        ARGS_FLAG=()
        [[ -n "$args" ]] && ARGS_FLAG=(-a "$args")
        CPUS_FLAG=$([[ "$CPU_RANGE" == "" ]] && echo "" || echo "-p $CPU_RANGE")
        
        if [ $DUMMY == 1 ] ; then
            #dummy
            echo "$ANALIZE_SCRIPT_PATH -c -e -o $fuzz_out_dir -p $CPU_RANGE $ARGS_FLAG $coverage_build $deduplication_build"
        else
            #real
            $ANALIZE_SCRIPT_PATH -c -e "${ARGS_FLAG[@]}" $CPUS_FLAG -o $fuzz_out_dir $coverage_build $deduplication_build
        fi
    done
done


