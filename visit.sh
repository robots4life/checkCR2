#!/bin/bash

# Check if a folder path is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <folder_path>"
  exit 1
fi

# Set the parent folder path
parent_folder="$1"

# Delete the existing "folder_tree.txt" file if it exists
folder_tree_file="$parent_folder/folder_tree.txt"
if [ -f "$folder_tree_file" ]; then
  rm "$folder_tree_file"
fi

# Create a new "folder_tree.txt" file in the parent folder
touch "$folder_tree_file"

# Recursively traverse subfolders and write paths to "folder_tree.txt"
find "$parent_folder" -type d | grep -v "^$parent_folder$" >>"$folder_tree_file"

# Output the folder tree to the terminal
echo "Folder tree:"
cat "$folder_tree_file"
