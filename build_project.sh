#! /bin/bash

# Usage function
usage() {
    echo "Usage: $0 -c <compiler> -s <sanitizers> -f <fuzzing_mode> -b <build_type> <project_path>"
    echo "  -c    Compiler (e.g., aflpp, aflppdouble, clang, auto) default is auto ans is used for multiple instrumentations"
    echo "  -s    Sanitizers (e.g., asan, ubsan, coverage, enumcoverage, debug)"
    echo "  -f    Fuzzing mode (e.g. fork, persistent)"
    echo "  -b    Builds (e.g., clang, aflpp, enumetric, enumetric++, enumetricbb++, enumetric_full ) will be also the name of the directory"
    echo "  <project_path> Path to the project to build"
    exit 1
}

# Get the current user's UID
current_uid=$(id -u)

# Default values
compiler="auto"
sanitizers="asan ubsan"
fuzzing_mode="persistent"
builds=""
project_path=""
ask_confirmation="true"

# Parse options
while getopts "yc:s:f:b:" opt; do
    case $opt in
        y) ask_confirmation="false" ;;
        c) compiler="$OPTARG" ;;
        s) sanitizers="$OPTARG" ;;
        f) fuzzing_mode="$OPTARG" ;;
        b) builds="$OPTARG" ;;
        *) usage ;;
    esac
done

# Shift processed options
shift $((OPTIND - 1))

# Remaining argument is the project path
if [[ $# -eq 1 ]]; then
    project_path="$1"
else
    echo "Error: You must specify a project path."
    usage
fi

# Validate inputs
if [[ -z "$compiler" || -z "$sanitizers" || -z "$fuzzing_mode" ]]; then
    echo "Error: All options (-c, -s, -f, -i) are required."
    usage
fi

if [[ ! -d "$project_path" ]]; then
    echo "Error: The specified project path does not exist or is not a directory: $project_path"
    exit 1
fi

if [[ "$ask_confirmation" == "true" ]] ; then
    # Display selected options
    echo "Compiler: $compiler"
    echo "Sanitizers: $sanitizers"
    echo "Fuzzing Mode: $fuzzing_mode"
    echo "Build: $builds"
    echo "Project Path: $project_path"
    echo ""

    # Prompt the user for confirmation
    read -p "Do you want to continue? (y/n): " choice

    # Check the user's input
    case "$choice" in
        y|Y )
            echo "Continuing..."
            ;;
        n|N )
            echo "Exiting..."
            exit 0
            ;;
        * )
            echo "Invalid input. Please enter 'y' or 'n'."
            exit 0
            ;;
    esac
fi


project_path=$(realpath $project_path)
echo $project_path
project_name=$(basename $project_path)
echo $project_name



docker build -t osvaldo/$project_name $project_path/  #--no-cache
# docker build -t osvaldo/$project_name $project_path/ 
if [ $? -eq 0 ]; then
    echo "Image created successfully."
else
    echo "Build of image failed."
    exit 1
fi


for build in $builds; do
  compiler_chosed=""
  if [ "$compiler" == "auto" ] ; then 
    if [ "$build" == "aflpp" ] ; then
      compiler_chosed="aflpp"
    fi
    if [ "$build" == "clang" ] ; then
      compiler_chosed="clang"
    fi
    if [ "$build" == "enumetric" ] || \
    [ "$build" == "enumetric++" ] || \
    [ "$build" == "enumetricbb++" ] || \
    [ "$build" == "enumetric_full" ]  ; then
      compiler_chosed="aflppdouble"
    fi
  else
    compiler_chosed=$compiler
  fi


  # Display selected options
  echo "Compiler: $compiler_chosed"
  echo "Sanitizers: $sanitizers"
  echo "Fuzzing Mode: $fuzzing_mode"
  echo "Build: $build"
  echo "Project Path: $project_path"
  echo ""

  sanitizers_env=""
  for sanitizer in $sanitizers; do
    if [[ "$sanitizer" == "asan" ]] ; then
        sanitizers_env="$sanitizers_env address"
    fi
    if [[ "$sanitizer" == "ubsan" ]] ; then
        sanitizers_env="$sanitizers_env undefined"
    fi
  done

  shift

  build_dir=$HOME/sut-docker/aflppdouble-v0.2.7/$project_name/$build/
  if [ -d "$build_dir" ]; then
      echo "$build_dir does exist."
      exit 1
  fi
  
  mkdir -p $build_dir

  docker run -it --rm \
    --env SANITIZERS="$sanitizers" \
    --env FUZZINGMODE="$fuzzing_mode" \
    --env COMPILER="$compiler_chosed" \
    --env BUILDTYPE="$build" \
    --env BUILD_UID=$current_uid \
    --env SANITIZER="$sanitizers_env" \
    -v $build_dir:/out -t osvaldo/$project_name

done

