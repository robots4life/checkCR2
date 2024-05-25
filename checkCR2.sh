#!/bin/bash

store_parent_folder() {
  if [ "$1" = "." ]; then
    parent_folder="$(pwd)"
  else
    parent_folder="$1"
  fi
  
  read -p "The parent folder is set to $parent_folder.
Is this correct? (y/n) " confirm
  case $confirm in
    y|Y) echo "Proceeding with the parent folder: $parent_folder";;
    n|N) echo "Exiting script."; exit 1;;
    *) echo "Invalid input. Exiting script."; exit 1;;
  esac
}

create_folder_tree() {
  # Check if a file named "folder_tree.txt" exists in the parent folder
  if [ -f "$parent_folder/folder_tree.txt" ]; then
    rm "$parent_folder/folder_tree.txt"
  fi

  # Create a new file named "folder_tree.txt" in the parent folder
  touch "$parent_folder/folder_tree.txt"

  # Traverse all subfolders of the parent folder
  while IFS= read -r -d '' subfolder; do
    # Check if the subfolder is named "damaged"
    if [ "$(basename "$subfolder")" = "damaged" ]; then
      rm -rf "$subfolder"
    else
      # Write the subfolder path to the "folder_tree.txt" file
      echo "$subfolder" >> "$parent_folder/folder_tree.txt"
    fi
  done < <(find "$parent_folder" -type d -print0)

  # Remove duplicate paths from the "folder_tree.txt" file
  sort -u "$parent_folder/folder_tree.txt" -o "$parent_folder/folder_tree.txt"

  # Print the "folder_tree.txt" file to the terminal
  cat "$parent_folder/folder_tree.txt"

  # Ask the user if the script should continue
  read -p "Do you want to continue executing further functions? (y/n) " continue_confirm
  case $continue_confirm in
    y|Y) echo "Continuing with the script.";;
    n|N) echo "Exiting script."; exit 0;;
    *) echo "Invalid input. Exiting script."; exit 1;;
  esac
}


# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <path/to/folder> or ."
  exit 1
fi

store_parent_folder "$1"
create_folder_tree
