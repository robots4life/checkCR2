#!/bin/bash

store_parent_folder() {
  if [ "$1" = "." ]; then
    parent_folder="$(pwd)"
  else
    # Remove the trailing slash if present
    parent_folder="${1%/}"
  fi

  read -p "The parent folder is set to $parent_folder.
Is this correct? (y/n) " confirm
  case $confirm in
  y | Y) echo "Proceeding with the parent folder: $parent_folder" ;;
  n | N)
    echo "Exiting script."
    exit 1
    ;;
  *)
    echo "Invalid input. Exiting script."
    exit 1
    ;;
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
      echo "$subfolder" >>"$parent_folder/folder_tree.txt"
    fi
  done < <(find "$parent_folder" -type d -print0)

  # Remove duplicate paths from the "folder_tree.txt" file
  sort -u "$parent_folder/folder_tree.txt" -o "$parent_folder/folder_tree.txt"

  # Print the "folder_tree.txt" file to the terminal
  cat "$parent_folder/folder_tree.txt"

  # Ask the user if the script should continue
  read -p "Do you want to continue executing further functions? (y/n) " continue_confirm
  case $continue_confirm in
  y | Y) echo "Continuing with the script." ;;
  n | N)
    echo "Exiting script."
    exit 0
    ;;
  *)
    echo "Invalid input. Exiting script."
    exit 1
    ;;
  esac
}

filter_image_files() {
  while IFS= read -r current_path; do
    echo "Filtering files in path $current_path.."

    # Delete existing text files
    find "$current_path" -maxdepth 1 -type f -name "files_paths.txt" -delete
    find "$current_path" -maxdepth 1 -type f -name "files_report.txt" -delete
    find "$current_path" -maxdepth 1 -type f -name "files_ok.txt" -delete
    find "$current_path" -maxdepth 1 -type f -name "files_damaged.txt" -delete

    # Create a new files_paths.txt file
    touch "$current_path/files_paths.txt"

    # Filter each file in the current path
    for file in "$current_path"/*; do
      if [ -f "$file" ]; then
        file_type=$(file --brief --mime-type "$file")
        case $file_type in
        image/*)
          echo "$file" >>"$current_path/files_paths.txt"
          ;;
        esac
      fi
    done
  done <"$parent_folder/folder_tree.txt"
}

check_CR2_image_metadata() {
  while IFS= read -r current_path; do
    # echo -e "\n"
    echo "Checking files in path $current_path.."

    # Check each file in the files_paths.txt file
    while IFS= read -r file; do

      file_mime_type=$(file -i "$file" | awk -F': ' '{print $2}' | sed 's/; charset=binary//')

      if [[ "$file_mime_type" == *"cr2"* ]]; then

        # File is a CR2 image
        echo "Checking $file_mime_type file $file"

        local metadata=$(dcraw -v -i "$file" 2>&1)
        local metadata_status=$?

        # Create files_report.txt if it doesn't exist
        if [ ! -f "$current_path/files_report.txt" ]; then
          touch "$current_path/files_report.txt"
        fi

        # Write the file path and dcraw output to files_report.txt
        echo "$file" >>"$current_path/files_report.txt"
        echo "$metadata" >>"$current_path/files_report.txt"
        echo >>"$current_path/files_report.txt"
        echo "File Metadata Exit Status Code = $metadata_status" >>"$current_path/files_report.txt"

        if [ $metadata_status -eq 0 ]; then
          echo "File Metadata OK" >>"$current_path/files_report.txt"

          # New function to check CR2 image thumbnail
          check_CR2_image_thumbnail
          copy_damaged_file "$file"

        else
          echo "File Metadata DAMAGED" >>"$current_path/files_report.txt"
          echo "File Metadata DAMAGED"
        fi

        echo >>"$current_path/files_report.txt"
        echo >>"$current_path/files_report.txt"
        echo >>"$current_path/files_report.txt"

      fi

    done <"$current_path/files_paths.txt"
  done <"$parent_folder/folder_tree.txt"
}

check_CR2_image_thumbnail() {
  local thumbnail_file="${file%.*}.thumb.jpg"
  dcraw -e "$file" >"$thumbnail_file" 2>/dev/null
  local thumbnail_status=$?

  if [ $thumbnail_status -eq 0 ]; then
    local identify_output=$(identify -regard-warnings "$thumbnail_file" 2>&1)

    if echo "$identify_output" | grep -q "Corrupt JPEG data"; then

      if [ ! -f "$current_path/files_damaged.txt" ]; then
        touch "$current_path/files_damaged.txt"
      fi

      echo "$file" >>"$current_path/files_damaged.txt"
      echo "$identify_output" >>"$current_path/files_damaged.txt"
      echo >>"$current_path/files_damaged.txt"
      echo >>"$current_path/files_damaged.txt"
      echo "File DAMAGED DATA"
      echo -e "\n"

      echo "$identify_output" >>"$current_path/files_report.txt"
      echo "File DAMAGED DATA" >>"$current_path/files_report.txt"

    else
      echo "File OK"
    fi
  fi

  # Remove the extracted thumbnail
  rm -f "$thumbnail_file"
}

copy_damaged_file() {
  local file="$1"
  local damaged_folder="$current_path/damaged"
  local filename=$(basename "$file")
  local extension="${filename##*.}"
  local base_filename="${filename%.*}"
  local new_filename="${base_filename}_damaged.${extension}"

  mkdir -p "$damaged_folder"
  cp "$file" "$damaged_folder/$new_filename"
}

check_image_files() {
  while IFS= read -r current_path; do
    # echo -e "\n"
    echo "Checking files in path $current_path.."

    # Check each file in the files_paths.txt file
    while IFS= read -r file; do

      file_mime_type=$(file -i "$file" | awk -F': ' '{print $2}' | sed 's/; charset=binary//')

      if [[ "$file_mime_type" == *"jpeg"* ]]; then

        local identify_output=$(identify -regard-warnings "$file" 2>&1)
        local status=$?

        if [ $status -eq 0 ]; then
          if echo "$identify_output" | grep -q "Corrupt JPEG data"; then

            if [ ! -f "$current_path/files_damaged.txt" ]; then
              touch "$current_path/files_damaged.txt"
            fi

            echo "$file" >>"$current_path/files_damaged.txt"
            echo "$identify_output" >>"$current_path/files_damaged.txt"
            echo >>"$current_path/files_damaged.txt"
            echo >>"$current_path/files_damaged.txt"
            echo "File DAMAGED DATA"
            echo -e "\n"

            echo "$identify_output" >>"$current_path/files_report.txt"
            echo "Checking $file_mime_type file $file"
            echo "File DAMAGED DATA" >>"$current_path/files_report.txt"

            copy_damaged_file "$file"

          fi
        fi
      fi

    done <"$current_path/files_paths.txt"
  done <"$parent_folder/folder_tree.txt"
}

# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <path/to/folder> or ."
  exit 1
fi

store_parent_folder "$1"
create_folder_tree
filter_image_files
check_CR2_image_metadata
check_image_files
