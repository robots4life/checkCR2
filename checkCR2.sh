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

# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <path/to/folder> or ."
  exit 1
fi

store_parent_folder "$1"

