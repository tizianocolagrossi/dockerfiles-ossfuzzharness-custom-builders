#!/bin/bash

# Check if a program path is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <program_path> <output_directory>"
    exit 1
fi

# Get the program path and output directory
program_path="$1"
out_dir="$2"

# Check if the program exists
if [ ! -f "$program_path" ]; then
    echo "Error: Program '$program_path' not found!"
    exit 1
fi

# Check if output directory is provided, if not set it to a default value
if [ -z "$out_dir" ]; then
    out_dir="./out"
fi

# Create the output directory if it does not exist
# mkdir -p "$out_dir"

# Use ldd to get the list of libraries used by the program
ldd "$program_path" | while read -r line; do
    # Only process lines with a valid path (those that are not "not found")
    # echo $line
    if [[ "$line" == *" => "* ]]; then
        echo "Copy $line"
        second_part=$(echo "$line" | cut -d'>' -f2-)
        file_path="${second_part%% (*}"
        echo $file_path
    fi
done

echo "Libraries copied to $out_dir"
