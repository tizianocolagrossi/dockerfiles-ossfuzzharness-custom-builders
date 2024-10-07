#! /bin/bash

# Destination directory where the symbolic links will be created
DEST_DIR="/lib/x86_64-linux-gnu/"

# Iterate over all files in the provided directory that start with 'lib'
for file in $IN/lib*; do
  if [ -f "$file" ]; then
    # Extract the base name of the file
    base_name=$(basename "$file")

    # Check if the symbolic link already exists
    if [ ! -e "$DEST_DIR/$base_name" ]; then
      # Create a symbolic link in the destination directory
      ln -s "$file" "$DEST_DIR/$base_name"
      echo "Created symlink for $base_name"
    else
      echo "Symlink for $base_name already exists"
    fi
  fi
done