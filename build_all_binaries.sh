#! /bin/bash

for project in ./sut-images/* ; do



    project_path=$(realpath $project)
    echo $project_path
    project_name=$(basename $project_path)
    echo $project_name

    docker build -t osvaldo/$project_name $project_path/

    for type in  aflppdouble_enumetric_full ; do # analysis baseline enumetric enumetric++ enumetricbb++ aflpp aflppdouble_baseline aflppdouble_enumetric aflppdouble_enumetric++ aflppdouble_enumetricbb++ aflppdouble_enumetric_full
        cmd=compile_$type
        echo $type
        echo $cmd
        build_dir=$HOME/sut-docker/$project_name/$type/
        if [ -d "$build_dir" ]; then
            echo "$build_dir does exist."
            continue
        fi
        mkdir -p $build_dir
        docker run -it --rm -v $build_dir:/out -t osvaldo/$project_name $cmd
    done 
done