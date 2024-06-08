#!/bin/bash

WHITE='\033[0;37m'
RED='\033[0;31m'
GREEN='\033[0;32m'

store_parent_directory() {

  if [ "$1" = "." ]; then
    parent_directory="$(pwd)"
  else
    # Remove the trailing slash if present
    parent_directory="${1%/}"
  fi
  echo ""
  echo "The parent directory is set to the following directory."
  echo ""
  echo "$parent_directory"
  echo ""

  # Get the modification time of the parent directory
  modification_time_parent_directory=$(stat -c %y "$parent_directory")
  creation_time_parent_directory=$(stat -c %w "$parent_directory")

  echo "original modi time : $modification_time_parent_directory"
  echo ""

  echo "original crea time : $creation_time_parent_directory"
  echo ""

  read -p "Is this correct? (y/n) " confirm
  echo ""
  case $confirm in
  y | Y) echo "Creating directory tree under the parent directory." ;;
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

create_directory_tree() {

  # Check if a file named "directory_tree.txt" exists in the parent directory
  if [ -f "$parent_directory/directory_tree.txt" ]; then
    rm "$parent_directory/directory_tree.txt"
  fi
  # Create a new file named "directory_tree.txt" in the parent directory
  touch "$parent_directory/directory_tree.txt"

  # Check if a file named "modification_times.txt" exists in the parent directory
  if [ -f "$parent_directory/modification_times.txt" ]; then
    rm "$parent_directory/modification_times.txt"
  fi
  # Create a new file named "modification_times.txt" in the parent directory
  touch "$parent_directory/modification_times.txt"

  # Check if a file named "creation_times.txt" exists in the parent directory
  if [ -f "$parent_directory/creation_times.txt" ]; then
    rm "$parent_directory/creation_times.txt"
  fi
  # Create a new file named "creation_times.txt" in the parent directory
  touch "$parent_directory/creation_times.txt"

  # Traverse all subdirectories of the parent directory
  while IFS= read -r -d '' subdirectory; do
    # Check if the subdirectory is named "damaged"
    if [ "$(basename "$subdirectory")" = "damaged" ]; then
      rm -rf "$subdirectory"
    else
      # Write the subdirectory path to the "directory_tree.txt" file
      echo "$subdirectory" >>"$parent_directory/directory_tree.txt"

      # Get the modification time of the subdirectory and write it to the "modification_times.txt" file
      modification_time=$(stat -c %y "$subdirectory")
      echo "$subdirectory:$modification_time" >>"$parent_directory/modification_times.txt"

      # Get the creation time of the subdirectory and write it to the "modification_times.txt" file
      creation_time_=$(stat -c %w "$subdirectory")
      echo "$subdirectory:$modification_time" >>"$parent_directory/creation_times.txt"
    fi
  done < <(find "$parent_directory" -type d -print0)

  # Remove duplicate paths from the "directory_tree.txt" file
  sort -u "$parent_directory/directory_tree.txt" -o "$parent_directory/directory_tree.txt"

  # Print the "directory_tree.txt" file to the terminal
  echo ""
  echo "This is the list of directories that will be checked."
  echo ""
  cat "$parent_directory/directory_tree.txt"

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
  done <"$parent_directory/directory_tree.txt"
}

check_CR2_image_metadata() {

  while IFS= read -r current_path; do

    # echo -e "\n"
    echo ""
    echo -e "${WHITE}Checking files in path $current_path.."
    echo ""

    # Create files_report_master.txt in parent directory if it doesn't exist
    if [ ! -f "$parent_directory/files_report_master.txt" ]; then
      touch "$parent_directory/files_report_master.txt"
    fi

    # Check each file in the files_paths.txt file
    while IFS= read -r file; do

      file_mime_type=$(file -i "$file" | awk -F': ' '{print $2}' | sed 's/; charset=binary//')

      # check CR2 files
      if [[ "$file_mime_type" == *"cr2"* ]]; then

        # File is a CR2 image
        echo -e "${WHITE}Checking $file_mime_type file $file"

        local metadata=$(dcraw -v -i "$file" 2>&1)
        local metadata_status=$?

        # Create files_report.txt if it doesn't exist
        # if [ ! -f "$current_path/files_report.txt" ]; then
        #   touch "$current_path/files_report.txt"
        # fi

        # Write the file path and dcraw output to files_report.txt in the current path
        # echo "$file" >>"$current_path/files_report.txt"
        # echo "$metadata" >>"$current_path/files_report.txt"
        # echo >>"$current_path/files_report.txt"
        # echo "File Metadata Exit Status Code = $metadata_status" >>"$current_path/files_report.txt"

        # Write the file path and dcraw output to files_report_master.txt in the parent directory
        echo "$file" >>"$parent_directory/files_report_master.txt"
        echo "$metadata" >>"$parent_directory/files_report_master.txt"

        echo >>"$parent_directory/files_report_master.txt" # add new line to file

        echo "File Metadata Exit Status Code = $metadata_status" >>"$parent_directory/files_report_master.txt"

        if [ $metadata_status -eq 0 ]; then
          # echo "File Metadata OK" >>"$current_path/files_report.txt"

          echo "File Metadata OK" >>"$parent_directory/files_report_master.txt"

          # New function to check CR2 image thumbnail
          # If the file header is OK check the file body
          check_CR2_image_thumbnail

        else
          # echo "File Metadata DAMAGED" >>"$current_path/files_report.txt"

          echo "File Metadata DAMAGED" >>"$parent_directory/files_report_master.txt"
          echo >>"$parent_directory/files_report_master.txt" # add new line to file
          echo "File Metadata DAMAGED"

        fi

        # echo >>"$current_path/files_report.txt"
        # echo >>"$current_path/files_report.txt"
        # echo >>"$current_path/files_report.txt"

        # echo >>"$parent_directory/files_report_master.txt"
        # echo >>"$parent_directory/files_report_master.txt"
        # echo >>"$parent_directory/files_report_master.txt"

      fi

      # check JPEG, PNG, GIF files
      if [[ "$file_mime_type" == *"jpeg"* ]] || [[ "$file_mime_type" == *"png"* ]] || [[ "$file_mime_type" == *"gif"* ]]; then

        # File is a JPEG image OR a PNG image OR a GIF image
        echo -e "${WHITE}Checking $file_mime_type file $file"

        local identify_output=$(identify -regard-warnings "$file" 2>&1)
        local status=$?

        if [ $status -eq 0 ]; then
          if echo "$identify_output" | grep -q "Corrupt JPEG data"; then

            # if [ ! -f "$current_path/files_damaged.txt" ]; then
            #   touch "$current_path/files_damaged.txt"
            # fi

            # Write file and output of check to files_damaged.txt in current path
            # echo "$file" >>"$current_path/files_damaged.txt"
            # echo "$identify_output" >>"$current_path/files_damaged.txt"
            # echo >>"$current_path/files_damaged.txt"
            # echo >>"$current_path/files_damaged.txt"

            # Write file and output of check to files_report.txt in current path
            # echo "$identify_output" >>"$current_path/files_report.txt"
            # echo "File DAMAGED DATA" >>"$current_path/files_report.txt"

            # Write the file path and output of check to files_report_master.txt in the parent directory
            # echo "$current_path" >>"$parent_directory/files_report_master.txt"
            # echo >>"$parent_directory/files_report_master.txt"

            # Write the file path and identify_output output to files_report_master.txt in the parent directory
            echo "$file" >>"$parent_directory/files_report_master.txt"
            echo "$identify_output" >>"$parent_directory/files_report_master.txt"
            echo "File DAMAGED DATA" >>"$parent_directory/files_report_master.txt"

            echo >>"$parent_directory/files_report_master.txt" # add new line to file
            echo >>"$parent_directory/files_report_master.txt" # add new line to file

            echo -e "${RED}File DAMAGED DATA"
            echo ""

            copy_damaged_file "$file"

          else
            # echo "$file" >>"$current_path/files_report.txt"
            # echo "File OK" >>"$current_path/files_report.txt"
            # echo >>"$current_path/files_report.txt"

            # echo "$file" >>"$parent_directory/files_report_master.txt"
            # echo "File OK" >>"$parent_directory/files_report_master.txt"
            # echo >>"$parent_directory/files_report_master.txt"

            echo -e "${GREEN}File OK"
            echo ""

          fi

        fi

      fi

    done <"$current_path/files_paths.txt"

  done <"$parent_directory/directory_tree.txt"
}

check_CR2_image_thumbnail() {

  local thumbnail_file="${file%.*}.thumb.jpg"
  dcraw -e "$file" >"$thumbnail_file" 2>/dev/null
  local thumbnail_status=$?

  if [ $thumbnail_status -eq 0 ]; then
    local identify_output=$(identify -regard-warnings "$thumbnail_file" 2>&1)

    if echo "$identify_output" | grep -q "Corrupt JPEG data"; then

      # copy orginal file to "damaged" directory in current path
      copy_damaged_file "$file"

      # if [ ! -f "$current_path/files_damaged.txt" ]; then
      #   touch "$current_path/files_damaged.txt"
      # fi

      # echo "$file" >>"$current_path/files_damaged.txt"
      # echo "$identify_output" >>"$current_path/files_damaged.txt"
      # echo >>"$current_path/files_damaged.txt"
      # echo >>"$current_path/files_damaged.txt"

      # echo "$identify_output" >>"$current_path/files_report.txt"
      # echo "File DAMAGED DATA" >>"$current_path/files_report.txt"

      echo "$identify_output" >>"$parent_directory/files_report_master.txt"
      echo "File DAMAGED DATA" >>"$parent_directory/files_report_master.txt"

      echo >>"$parent_directory/files_report_master.txt" # add new line to file
      echo >>"$parent_directory/files_report_master.txt" # add new line to file

      echo -e "${RED}File DAMAGED DATA"
      echo ""

    else
      # echo "File OK" >>"$current_path/files_report.txt"

      echo "File OK" >>"$parent_directory/files_report_master.txt"
      echo >>"$parent_directory/files_report_master.txt" # add new line to file

      echo -e "${GREEN}File OK"
      echo ""
    fi
  fi

  # Remove the extracted thumbnail
  rm -f "$thumbnail_file"
}

copy_damaged_file() {

  local file="$1"
  # instead of creating a damaged directory in each current path
  local damaged_directory="$current_path/damaged"

  # create a damaged directory in the parent directory and append the name of directory where the damaged files are to it
  # local damaged_directory="$parent_directory/$(basename "$current_path")_damaged"

  local filename=$(basename "$file")
  local extension="${filename##*.}"
  local base_filename="${filename%.*}"
  local new_filename="${base_filename}_damaged.${extension}"

  mkdir -p "$damaged_directory"
  cp "$file" "$damaged_directory/$new_filename"
}

remove_log_files() {

  echo ""
  echo -e "${WHITE}Removing log files.."

  while IFS= read -r current_path; do

    # If there is a "files_report.txt" in the current path
    # if [ -f "$current_path/files_report.txt" ]; then

    #   # If there are no errors remove the "files_report.txt"
    #   search_string="Corrupt"
    #   if ! grep -q "$search_string" "$current_path/files_report.txt"; then
    #     echo ""
    #     echo -e "${GREEN}No Errors found in all checked files - deleting files report."
    #     rm -f "$current_path/files_report.txt"
    #   fi
    # fi

    # If there is a "files_report_master.txt" in the parent directory
    if [ -f "$parent_directory/files_report_master.txt" ]; then

      # If there are no errors remove the "files_report_master.txt"
      search_string="Corrupt"
      if ! grep -q "$search_string" "$parent_directory/files_report_master.txt"; then
        echo ""
        echo -e "${GREEN}No Errors found in all files report master - deleting files report master."
        rm -f "$parent_directory/files_report_master.txt"
      fi
    fi

    rm -f "$current_path/files_paths.txt"
    rm -f "$current_path/directory_tree.txt"
    rm -f "$current_path/files_damaged.txt"

  done <"$parent_directory/directory_tree.txt"

  echo ""
  echo -e "${WHITE}Done."
  echo ""
}

restore_original_modification_and_creation_times() {

  # Check if the "modification_times.txt" file exists
  if [ -f "$parent_directory/modification_times.txt" ]; then
    # Traverse all lines in the "modification_times.txt" file
    while IFS=':' read -r directory modification_time; do
      # Restore the original modification time for the directory
      touch -d "$modification_time" "$directory"
    done <"$parent_directory/modification_times.txt"
  else
    echo "Error: modification_times.txt file not found."
    exit 1
  fi

  rm -f $parent_directory/modification_times.txt
  touch -d "$creation_time_parent_directory" "$parent_directory"

  # Check if the "creation_times.txt" file exists
  if [ -f "$parent_directory/creation_times.txt" ]; then
    # Traverse all lines in the "creation_times.txt" file
    while IFS=':' read -r directory creation_time; do
      # Restore the original creation time for the directory
      touch -d "$creation_time" "$directory"
    done <"$parent_directory/creation_times.txt"
  else
    echo "Error: creation_times.txt file not found."
    exit 1
  fi

  rm -f $parent_directory/creation_times.txt
  touch -d "$creation_time_parent_directory" "$parent_directory"

}

# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <path/to/directory> or ."
  exit 1
fi

store_parent_directory "$1"
create_directory_tree
filter_image_files
check_CR2_image_metadata
remove_log_files
restore_original_modification_and_creation_times
