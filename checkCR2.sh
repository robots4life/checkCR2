#!/bin/bash

# Function to check if a file is damaged
check_file() {
    local file="$1"
    local file_type=$(file -b --mime-type "$file")

    if [ "$file_type" == "image/x-canon-cr2" ]; then
        local thumbnail_file="${file%.*}.thumb.jpg"
        dcraw -e "$file" > "$thumbnail_file" 2>/dev/null
        local thumbnail_status=$?

        local metadata=$(dcraw -v -i "$file" 2>&1)
        local metadata_status=$?

        if [ $metadata_status -eq 0 ]; then
            if [ $thumbnail_status -eq 0 ]; then
                local identify_output=$(identify -regard-warnings "$thumbnail_file" 2>&1)
                if echo "$identify_output" | grep -q "Corrupt JPEG data"; then
                    echo "$file" >> "$folder/files_damaged.txt"
                    echo "$metadata" >> "$folder/files_damaged.txt"
                    echo "$identify_output" >> "$folder/files_damaged.txt"
                    echo "" >> "$folder/files_damaged.txt"
                    echo "" >> "$folder/files_damaged.txt"
                    echo "- $file" >> "$folder/files_report.txt"
                    echo "$metadata" >> "$folder/files_report.txt"
                    echo "Thumbnail extracted: $thumbnail_file" >> "$folder/files_report.txt"
                    echo "$identify_output" >> "$folder/files_report.txt"
                    echo "File DAMAGED DATA" >> "$folder/files_report.txt"
                    echo "" >> "$folder/files_report.txt"
                    echo "" >> "$folder/files_report.txt"
                    echo "File DAMAGED DATA" >&2
                    copy_damaged_file "$file"
                else
                    echo "$file" >> "$folder/files_ok.txt"
                    echo "- $file" >> "$folder/files_report.txt"
                    echo "$metadata" >> "$folder/files_report.txt"
                    echo "Thumbnail extracted: $thumbnail_file" >> "$folder/files_report.txt"
                    echo "$identify_output" >> "$folder/files_report.txt"
                    echo "File OK" >> "$folder/files_report.txt"
                    echo "" >> "$folder/files_report.txt"
                    echo "" >> "$folder/files_report.txt"
                fi
            else
                echo "$file" >> "$folder/files_damaged.txt"
                echo "$metadata" >> "$folder/files_damaged.txt"
                echo "Failed to extract thumbnail" >> "$folder/files_damaged.txt"
                echo "" >> "$folder/files_damaged.txt"
                echo "" >> "$folder/files_damaged.txt"
                echo "- $file" >> "$folder/files_report.txt"
                echo "$metadata" >> "$folder/files_report.txt"
                echo "Failed to extract thumbnail" >> "$folder/files_report.txt"
                echo "File DAMAGED DATA" >> "$folder/files_report.txt"
                echo "" >> "$folder/files_report.txt"
                echo "" >> "$folder/files_report.txt"
                echo "File DAMAGED DATA" >&2
                copy_damaged_file "$file"
            fi
        else
            echo "$file" >> "$folder/files_damaged.txt"
            echo "$metadata" >> "$folder/files_damaged.txt"
            echo "File DAMAGED HEADER" >> "$folder/files_damaged.txt"
            echo "" >> "$folder/files_damaged.txt"
            echo "" >> "$folder/files_damaged.txt"
            echo "- $file" >> "$folder/files_report.txt"
            echo "$metadata" >> "$folder/files_report.txt"
            echo "File DAMAGED HEADER" >> "$folder/files_report.txt"
            echo "" >> "$folder/files_report.txt"
            echo "" >> "$folder/files_report.txt"
            echo "File DAMAGED HEADER" >&2
            copy_damaged_file "$file"
        fi

        # Remove the extracted thumbnail
        rm -f "$thumbnail_file"
    elif [ "$file_type" == "image/jpeg" ] || [ "$file_type" == "image/png" ]; then
        local identify_output=$(identify -regard-warnings "$file" 2>&1)
        local status=$?

        if [ $status -eq 0 ]; then
            if echo "$identify_output" | grep -q "Corrupt JPEG data"; then
                echo "$file" >> "$folder/files_damaged.txt"
                echo "$identify_output" >> "$folder/files_damaged.txt"
                echo "" >> "$folder/files_damaged.txt"
                echo "" >> "$folder/files_damaged.txt"
                echo "- $file" >> "$folder/files_report.txt"
                echo "$identify_output" >> "$folder/files_report.txt"
                echo "File DAMAGED DATA" >> "$folder/files_report.txt"
                echo "" >> "$folder/files_report.txt"
                echo "" >> "$folder/files_report.txt"
                echo "File DAMAGED DATA" >&2
                copy_damaged_file "$file"
            else
                echo "$file" >> "$folder/files_ok.txt"
                echo "- $file" >> "$folder/files_report.txt"
                echo "$identify_output" >> "$folder/files_report.txt"
                echo "File OK" >> "$folder/files_report.txt"
                echo "" >> "$folder/files_report.txt"
                echo "" >> "$folder/files_report.txt"
            fi
        else
            echo "$file" >> "$folder/files_damaged.txt"
            echo "$identify_output" >> "$folder/files_damaged.txt"
            echo "" >> "$folder/files_damaged.txt"
            echo "" >> "$folder/files_damaged.txt"
            echo "- $file" >> "$folder/files_report.txt"
            echo "$identify_output" >> "$folder/files_report.txt"
            echo "File DAMAGED HEADER" >> "$folder/files_report.txt"
            echo "" >> "$folder/files_report.txt"
            echo "" >> "$folder/files_report.txt"
            echo "File DAMAGED HEADER" >&2
            copy_damaged_file "$file"
        fi
    fi
}

# Function to copy damaged files to the "damaged" folder
copy_damaged_file() {
    local file="$1"
    local damaged_folder="$folder/damaged"
    local filename=$(basename "$file")
    local extension="${filename##*.}"
    local base_filename="${filename%.*}"
    local new_filename="${base_filename}_damaged.${extension}"

    mkdir -p "$damaged_folder"
    cp "$file" "$damaged_folder/$new_filename"
}

# Check if a folder is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <folder_path>"
    exit 1
fi

folder="$1"

# Check if the text files exist and delete them
for file in "$folder"/files_damaged.txt "$folder"/files_ok.txt "$folder"/files_paths.txt "$folder"/files_report.txt; do
    if [ -f "$file" ]; then
        rm "$file"
    fi
done

# Create new text files
> "$folder/files_paths.txt"
> "$folder/files_damaged.txt"
> "$folder/files_ok.txt"
> "$folder/files_report.txt"

# Check if the "damaged" folder exists and delete it
if [ -d "$folder/damaged" ]; then
    rm -rf "$folder/damaged"
fi

# Create a new "damaged" folder
mkdir "$folder/damaged"

# Find all files in the folder
echo "Finding files in $folder..."
find "$folder" -type f -print0 | while IFS= read -r -d '' file; do
    echo "$file" >> "$folder/files_paths.txt"
done

# Check each file
echo "Checking files..."
while read -r file; do
    echo "Checking $file..."
    check_file "$file"
done < "$folder/files_paths.txt"

echo "Done!"
