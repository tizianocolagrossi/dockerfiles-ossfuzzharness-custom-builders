#! /bin/bash

OSS_FUZZ_DIR=$HOME/oss-fuzz/

if [ ! -d "$OSS_FUZZ_DIR" ]; then
    echo "$OSS_FUZZ_DIR does not exist. cloning..."
    git clone --depth 1 https://github.com/google/oss-fuzz.git $OSS_FUZZ_DIR
fi

PROECT_REQUESTED=$1
DEST_DIR=$2
BUILDER_IMAGE=$3
ENUMETRIC_VERSION=$4

if [[ -z "$PROECT_REQUESTED" ]] || [[ -z "$DEST_DIR" ]] || [[ -z "$BUILDER_IMAGE" ]]|| [[ -z "$ENUMETRIC_VERSION" ]];
  then
    echo "Need project to setup and destination dir"
    echo "Example: $0 project_name destination_dir builder_image version_image"
    exit 0
fi

if [ "$PROECT_REQUESTED" == "ls" ]
  then
    ls $OSS_FUZZ_DIR/projects/
    exit 0
fi

PROJECT_DIR=$OSS_FUZZ_DIR/projects/$PROECT_REQUESTED

mkdir -p $DEST_DIR
cp -r $PROJECT_DIR $DEST_DIR

# Escape the forward slashes
ESCAPED_BUILDER_IMAGE=$(echo "$BUILDER_IMAGE" | sed 's/\//\\\//g')

sed -i "s/FROM gcr\.io\/oss-fuzz-base\/base-builder/FROM $ESCAPED_BUILDER_IMAGE:$ENUMETRIC_VERSION/g" $DEST_DIR/$PROECT_REQUESTED/Dockerfile 
