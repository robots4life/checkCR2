#!/bin/bash

# Function to check if a file is damaged
check_file() {
    local file="$1"
    local file_type=$(file -b --mime-type "$file")

    if [ "$file_type" == "image/x-canon-cr2" ]; then
        # ... (rest of the function remains unchanged)
    elif [ "$file_type" == "image/jpeg" ] || [ "$file_type" == "image/png" ]; then
        # ... (rest of the function remains unchanged)
    fi
}

# Function to copy damaged files to the "damaged" folder
copy_damaged_file() {
    local file="$1"
    local damaged_folder="$parent_folder/damaged"
    local filename=$(basename "$file")
    local extension="${filename##*.}"
    local base_filename="${filename%.*}"
    local new_filename="${base_filename}_damaged.${extension}"

    mkdir -p "$damaged_folder"
    cp "$file" "$damaged_folder/$new_filename"
}

# Function to recursively traverse subfolders and write paths to folder_tree.txt
traverse_subfolders() {
    local folder="$1"
    echo "$folder" >> "$parent_folder/folder_tree.txt"

    for subfolder in "$folder"/*/; do
        if [ -d "$subfolder" ]; then
            traverse_subfolders "$subfolder"
        fi
    done
}

# Check if a folder is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <folder_path>"
    exit 1
fi

parent_folder="$1"

# Check if the text files exist and delete them
for file in "$parent_folder"/files_damaged.txt "$parent_folder"/files_ok.txt "$parent_folder"/files_paths.txt "$parent_folder"/files_report.txt "$parent_folder"/folder_tree.txt; do
    if [ -f "$file" ]; then
        rm "$file"
    fi
done

# Create new text files
> "$parent_folder/files_paths.txt"
> "$parent_folder/files_damaged.txt"
> "$parent_folder/files_ok.txt"
> "$parent_folder/files_report.txt"
> "$parent_folder/folder_tree.txt"

# Check if the "damaged" folder exists and delete it
if [ -d "$parent_folder/damaged" ]; then
    rm -rf "$parent_folder/damaged"
fi

# Create a new "damaged" folder
mkdir "$parent_folder/damaged"

# Find all files in the parent folder and subfolders
echo "Finding files in $parent_folder and subfolders..."
find "$parent_folder" -type f -print0 | while IFS= read -r -d '' file; do
    echo "$file" >> "$parent_folder/files_paths.txt"
done

# Traverse subfolders and write paths to folder_tree.txt
traverse_subfolders "$parent_folder"

# Check each file
echo "Checking files..."
while read -r file; do
    echo "Checking $file..."
    check_file "$file"
done < "$parent_folder/files_paths.txt"

echo "Done!"
