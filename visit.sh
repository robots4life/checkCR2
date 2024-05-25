#!/bin/bash

# Check if a folder path is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <folder_path>"
  exit 1
fi

# Set the parent folder path
parent_folder="$1"

# Create the "folder_tree.txt" file in the parent folder
folder_tree_file="$parent_folder/folder_tree.txt"
touch "$folder_tree_file"

# Recursively traverse subfolders and write paths to "folder_tree.txt"
find "$parent_folder" -type d | while read -r folder; do
  echo "$folder" >> "$folder_tree.txt"
done

# Ask the user if each found folder should be visited
read -p "Do you want to visit each found folder? (y/n) " confirm
if [ "$confirm" != "y" ]; then
  echo "Exiting without visiting folders."
  exit 0
fi

# Visit each folder listed in "folder_tree.txt"
while read -r folder; do
  # Create the "visited.txt" file in the current folder
  visited_file="$folder/visited.txt"
  touch "$visited_file"
  
  # Write the current date and time to "visited.txt"
  current_date=$(date)
  echo "Visited on: $current_date" >> "$visited_file"
  
  echo "Created 'visited.txt' in folder: $folder"
done < "$folder_tree.txt"

echo "Folder visiting process completed."
