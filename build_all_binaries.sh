#! /bin/bash

for project in ./sut-images/* ; do
    project_path=$(realpath $project)
    echo $project_path
    project_name=$(basename $project_path)
    echo $project_name

    docker build -t fuzzbuild/$project_name $project_path/

    for type in analysis baseline enumetric enumetric++ ; do
        cmd=compile_$type
        echo $type
        echo $cmd
        build_dir=$HOME/sut-docker/$project_name/$type/
        mkdir -p $build_dir
        docker run -it --rm -v $build_dir:/out -t fuzzbuild/$project_name $cmd
    done 
done