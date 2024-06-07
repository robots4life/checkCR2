#!/bin/bash

WHITE='\033[0;37m'
RED='\033[0;31m'
GREEN='\033[0;32m'

store_parent_folder() {
  if [ "$1" = "." ]; then
    parent_folder="$(pwd)"
  else
    # Remove the trailing slash if present
    parent_folder="${1%/}"
  fi
  echo ""
  echo "The parent folder is set to the following folder."
  echo ""
  echo "$parent_folder"
  echo ""
  read -p "Is this correct? (y/n) " confirm
  echo ""
  case $confirm in
  y | Y) echo "Creating folder tree under the parent folder." ;;
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
  echo ""
  echo "This is the list of folders that will be checked."
  echo ""
  cat "$parent_folder/folder_tree.txt"

  # Ask the user if the script should continue
  echo ""
  read -p "Do you want to continue executing further functions? (y/n) " continue_confirm
  echo ""
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
    echo ""
    echo "Generating list of image files to check in $current_path.."

    # Delete existing text files
    find "$current_path" -maxdepth 1 -type f -name "files_paths.txt" -delete
    find "$current_path" -maxdepth 1 -type f -name "files_report.txt" -delete
    find "$current_path" -maxdepth 1 -type f -name "files_report_master.txt" -delete
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
    echo ""
    echo -e "${WHITE}Checking files in path $current_path.."
    echo ""

    # Create files_report_master.txt in parent folder if it doesn't exist
    if [ ! -f "$parent_folder/files_report_master.txt" ]; then
      touch "$parent_folder/files_report_master.txt"
    fi

    # Check each file in the files_paths.txt file
    while IFS= read -r file; do

      file_mime_type=$(file -i "$file" | awk -F': ' '{print $2}' | sed 's/; charset=binary//')

      if [[ "$file_mime_type" == *"cr2"* ]]; then

        # File is a CR2 image
        echo -e "${WHITE}Checking $file_mime_type file $file"

        local metadata=$(dcraw -v -i "$file" 2>&1)
        local metadata_status=$?

        # Create files_report.txt if it doesn't exist
        if [ ! -f "$current_path/files_report.txt" ]; then
          touch "$current_path/files_report.txt"
        fi

        # Write the file path and dcraw output to files_report.txt in the current path
        echo "$file" >>"$current_path/files_report.txt"
        echo "$metadata" >>"$current_path/files_report.txt"
        echo >>"$current_path/files_report.txt"
        echo "File Metadata Exit Status Code = $metadata_status" >>"$current_path/files_report.txt"

        # Write the file path and dcraw output to files_report_master.txt in the parent folder
        echo "$current_path" >>"$parent_folder/files_report_master.txt"
        echo >>"$parent_folder/files_report_master.txt"

        echo "$file" >>"$parent_folder/files_report_master.txt"
        echo "$metadata" >>"$parent_folder/files_report_master.txt"
        echo >>"$parent_folder/files_report_master.txt"

        echo "File Metadata Exit Status Code = $metadata_status" >>"$parent_folder/files_report_master.txt"

        if [ $metadata_status -eq 0 ]; then
          echo "File Metadata OK" >>"$current_path/files_report.txt"

          # New function to check CR2 image thumbnail
          # If the file header is OK check the file body
          check_CR2_image_thumbnail

        else
          echo "File Metadata DAMAGED" >>"$current_path/files_report.txt"
          echo "File Metadata DAMAGED" >>"$parent_folder/files_report_master.txt"
          echo "File Metadata DAMAGED"
        fi

        echo >>"$current_path/files_report.txt"
        echo >>"$current_path/files_report.txt"
        echo >>"$current_path/files_report.txt"

        echo >>"$parent_folder/files_report_master.txt"
        echo >>"$parent_folder/files_report_master.txt"
        echo >>"$parent_folder/files_report_master.txt"

      fi

      if [[ "$file_mime_type" == *"jpeg"* ]] || [[ "$file_mime_type" == *"png"* ]] || [[ "$file_mime_type" == *"gif"* ]]; then

        # File is a JPEG image OR a PNG image OR a GIF image
        echo -e "${WHITE}Checking $file_mime_type file $file"

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
            echo -e "${RED}File DAMAGED DATA"
            echo ""

            echo "$identify_output" >>"$current_path/files_report.txt"
            echo "File DAMAGED DATA" >>"$current_path/files_report.txt"

            # Write the file path and identify_output output to files_report_master.txt in the parent folder
            echo "$current_path" >>"$parent_folder/files_report_master.txt"
            echo >>"$parent_folder/files_report_master.txt"

            echo "$file" >>"$parent_folder/files_report_master.txt"
            echo "$identify_output" >>"$parent_folder/files_report_master.txt"
            echo "File DAMAGED DATA" >>"$parent_folder/files_report_master.txt"
            echo >>"$parent_folder/files_report_master.txt"

            copy_damaged_file "$file"

          else
            echo -e "${GREEN}File OK"
            echo ""

          fi

        fi

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

      # copy orginal file to "damaged" folder in current path
      copy_damaged_file "$file"

      if [ ! -f "$current_path/files_damaged.txt" ]; then
        touch "$current_path/files_damaged.txt"
      fi

      echo "$file" >>"$current_path/files_damaged.txt"
      echo "$identify_output" >>"$current_path/files_damaged.txt"
      echo >>"$current_path/files_damaged.txt"
      echo >>"$current_path/files_damaged.txt"
      echo -e "${RED}File DAMAGED DATA"
      echo ""

      echo "$identify_output" >>"$current_path/files_report.txt"
      echo "File DAMAGED DATA" >>"$current_path/files_report.txt"

      echo "$identify_output" >>"$parent_folder/files_report_master.txt"
      echo "File DAMAGED DATA" >>"$parent_folder/files_report_master.txt"

    else
      echo -e "${GREEN}File OK"
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

remove_log_files() {
  echo ""
  echo -e "${WHITE}Removing log files.."
  while IFS= read -r current_path; do

    # If there is a "files_report.txt" in the current path
    if [ -f "$current_path/files_report.txt" ]; then

      # If there are no errors remove the "files_report.txt"
      search_string="Corrupt"
      if ! grep -q "$search_string" "$current_path/files_report.txt"; then
        echo ""
        echo -e "${GREEN}No Errors found in all checked files - deleting files report."
        rm -f "$current_path/files_report.txt"
      fi
    fi

    # If there is a "files_report_master.txt" in the current path
    if [ -f "$current_path/files_report_master.txt" ]; then

      # If there are no errors remove the "files_report_master.txt"
      search_string="Corrupt"
      if ! grep -q "$search_string" "$current_path/files_report_master.txt"; then
        echo ""
        echo -e "${GREEN}No Errors found in all checked files - deleting files report master."
        rm -f "$current_path/files_report_master.txt"
      fi
    fi

    rm -f "$current_path/folder_tree.txt"
    rm -f "$current_path/files_paths.txt"
  done <"$parent_folder/folder_tree.txt"

  echo ""
  echo -e "${WHITE}Done."
  echo ""
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
remove_log_files
