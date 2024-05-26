# Check CR2 files for corrupted data

1.

This script assumes that both `dcraw` and `identify` (from ImageMagick) are installed and available in your system's PATH.

<a href="https://www.dechifro.org/dcraw/">https://www.dechifro.org/dcraw/</a>

<a href="https://imagemagick.org/script/identify.php">https://imagemagick.org/script/identify.php</a>

If not, you may need to provide the full paths to the executables in the script.

```shell
sudo apt-get install dcraw
```

2.

```shell
chmod +x checkCR2.sh
```

3.

```
checkCR2.sh /path/to/folder_with_cr2_files/to_check
```

This script

- creates a list of all subfolders given the parent folder passed in as argument
- leaves the original files untouched
- checks the CR2 files metadata
- checks the extracted JPEG file from the CR2 file for corruption
- if no file corruption is found in the temporary JPEG file the JPEG file is deleted
- if file corruption is present the affected CR2 file will be copied to a "damaged" folder in the current path, the temporary JPEG file will be deleted and not copied to the "damaged" folder
- a detailed file report will be generated
- a list of all damaged files will be generated
- if all files are ok all log files and temporary files will be deleted
