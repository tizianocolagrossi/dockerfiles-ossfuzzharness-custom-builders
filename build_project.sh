#! /bin/bash

if [ "$#" -ne 1 ]
then
  echo "USAGE: $0 <project-path>"
  exit 1
fi


project_path=$(realpath $1)
echo $project_path
project_name=$(basename $project_path)
echo $project_name

docker build -t fuzzbuild/$project_name $project_path/

for type in analysis baseline enumetric enumetric++ ; do
    cmd=compile_$type
    echo $type
    echo $cmd
    build_dir=$HOME/sut-docker/$project_name/$type/
    if [ -d "$build_dir" ]; then
        echo "$build_dir does exist."
        continue
    fi
    mkdir -p $build_dir
    #docker run -it --rm -v $build_dir:/out -t fuzzbuild/$project_name /bin/bash
    docker run -it --rm -v $build_dir:/out -t fuzzbuild/$project_name $cmd
done 