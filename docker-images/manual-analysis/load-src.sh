#! /bin/bash

# Destination directory where the symbolic links will be created
DEST_DIR_SRC="/src/"
# DEST_DIR_USR="/src/"

# Iterate over all files in the provided directory that start with 'lib'
for file in $IN/src/*; do
  if [ -e "$file" ]; then
    # Extract the base name of the file
    base_name=$(basename "$file")

    # Check if the symbolic link already exists
    if [ ! -e "$DEST_DIR_SRC/$base_name" ]; then
      # Create a symbolic link in the destination directory
      ln -s "$file" "$DEST_DIR_SRC/"
      echo "Created symlink for $base_name"
    else
      echo "Symlink for $base_name already exists"
    fi
  fi
done

DEST_DIR_SRC="/usr/include/"
for file in $IN/usr/include/*; do
  if [ -e "$file" ]; then
    # Extract the base name of the file
    base_name=$(basename "$file")

    # Check if the symbolic link already exists
    if [ ! -e "$DEST_DIR_SRC/$base_name" ]; then
      # Create a symbolic link in the destination directory
      ln -s "$file" "$DEST_DIR_SRC/"
      echo "Created symlink for $base_name"
    else
      echo "Symlink for $base_name already exists"
    fi
  fi
done

DEST_DIR_SRC="/work/"
for file in $IN/work/*; do
  if [ -e "$file" ]; then
    # Extract the base name of the file
    base_name=$(basename "$file")

    # Check if the symbolic link already exists
    if [ ! -e "$DEST_DIR_SRC/$base_name" ]; then
      # Create a symbolic link in the destination directory
      ln -s "$file" "$DEST_DIR_SRC/"
      echo "Created symlink for $base_name"
    else
      echo "Symlink for $base_name already exists"
    fi
  fi
done