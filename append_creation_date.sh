#!/bin/bash

# Usage: ./append_creation_date.sh filename

file="$1"

if [[ ! -f "$file" ]]; then
    echo "File does not exist: $file"
    exit 1
fi

# Get creation time in epoch
creation_epoch_formatted=$(stat -c "time:%W" "$file")
creation_epoch=$(stat -c "%W" "$file")

# If creation time is zero (unknown), fallback to modification time
if [[ "$creation_epoch" -eq 0 ]]; then
    creation_epoch_formatted=$(stat -c "modification:%Y" "$file")
fi

# Extract filename components
filename=$(basename -- "$file")
extension="${filename##*.}"
basename="${filename%.*}"

# Handle files without extension
if [[ "$filename" == "$extension" ]]; then
    new_filename="${filename},${creation_epoch_formatted}"
else
    new_filename="${basename},${creation_epoch_formatted}.${extension}"
fi

# Rename the file
mv "$file" "$new_filename"
echo "Renamed to: $new_filename"
