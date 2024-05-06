#! /bin/bash

DEST_DIR=$HOME/sut-images
DEST_DIR_OUTPUT_BINARIES=$HOME/sut

if [[ ! -d $DEST_DIR ]]; then
  mkdir -p $DEST_DIR
fi

if [[ ! -d $DEST_DIR_OUTPUT_BINARIES ]]; then
  mkdir -p $DEST_DIR_OUTPUT_BINARIES
fi

OSS_FUZZ_DIR=$HOME/oss-fuzz/

if [ ! -d "$OSS_FUZZ_DIR" ]; then
    echo "$OSS_FUZZ_DIR does not exist. cloning..."
    git clone --depth 1 https://github.com/google/oss-fuzz.git $OSS_FUZZ_DIR
fi

PROECT_REQUESTED=$1
BUILDER_IMAGE=$2
ENUMETRIC_VERSION=$3

if [ "$PROECT_REQUESTED" == "ls" ]
  then
    ls $OSS_FUZZ_DIR/projects/
    exit 0
fi

if [[ -z "$PROECT_REQUESTED" ]] || [[ -z "$BUILDER_IMAGE" ]] || [[ -z "$ENUMETRIC_VERSION" ]];
  then
    echo "Need project to setup and destination dir"
    echo "Example: $0 project_name builder_image version_image"
    exit 0
fi

if [[ "$BUILDER_IMAGE" == "*/*" ]] || [[ "$BUILDER_IMAGE" == "*\*" ]];
  then
    echo "Error the name of the builder image cannot contain \ or /."
    exit 0
fi

if [[ "$ENUMETRIC_VERSION" == "*/*" ]] || [[ "$ENUMETRIC_VERSION" == "*\*" ]];
  then
    echo "Error the version of enumetric cannot contain \ or /."
    exit 0
fi

PROJECT_DIR=$OSS_FUZZ_DIR/projects/$PROECT_REQUESTED

DEST_PROJECT_DIR=$DEST_DIR/$PROECT_REQUESTED-$BUILDER_IMAGE:$ENUMETRIC_VERSION

mkdir -p $DEST_DIR
cp -r $PROJECT_DIR $DEST_PROJECT_DIR


sed -i "s/FROM gcr\.io\/oss-fuzz-base\/base-builder.*/FROM $BUILDER_IMAGE:$ENUMETRIC_VERSION/g" $DEST_PROJECT_DIR/Dockerfile 

docker build -t $PROECT_REQUESTED-$BUILDER_IMAGE:$ENUMETRIC_VERSION  $DEST_PROJECT_DIR/ 

touch $DEST_PROJECT_DIR/$PROECT_REQUESTED-$BUILDER_IMAGE:$ENUMETRIC_VERSION.imagetagname

## analysis image
PROJECT_ANALYSIS_DIR=$DEST_DIR/$PROECT_REQUESTED-$BUILDER_IMAGE-analysis:$ENUMETRIC_VERSION
if [[ ! -d $PROJECT_ANALYSIS_DIR ]]; then
  mkdir -p $PROJECT_ANALYSIS_DIR
  cp -r $PROJECT_DIR/* $PROJECT_ANALYSIS_DIR

  ANALYSIS_IMAGE=enumetric-analysis
  sed -i "s/FROM gcr\.io\/oss-fuzz-base\/base-builder.*/FROM $ANALYSIS_IMAGE:$ENUMETRIC_VERSION/g" $PROJECT_ANALYSIS_DIR/Dockerfile 
  docker build -t $PROECT_REQUESTED-$BUILDER_IMAGE-analysis:$ENUMETRIC_VERSION  $PROJECT_ANALYSIS_DIR/ 
  touch $PROJECT_ANALYSIS_DIR/$PROECT_REQUESTED-$BUILDER_IMAGE-analysis:$ENUMETRIC_VERSION.imagetagname
fi

## attempting to create fuzzer files
docker run --rm -v $DEST_DIR_OUTPUT_BINARIES/enumetric-version-$ENUMETRIC_VERSION/$PROECT_REQUESTED/:/out -t $PROECT_REQUESTED-$BUILDER_IMAGE:$ENUMETRIC_VERSION
