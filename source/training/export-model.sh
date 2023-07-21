#!/bin/bash
cd $SIMPLEVIS_DATA/workspace
yolo export model=${SIMPLEVIS_DATA}/workspace/$BASE_MODEL format=torchscript

# Set the filename with .pt extension
file_name=$BASE_MODEL

# Check if the file exists
if [ -f "$file_name" ]; then
    # Replace .pt with .torchscript in the filename
    new_name="${file_name%.pt}.torchscript"
    mv "$file_name" "$new_name"
    echo "Renamed '$file_name' to '$new_name'"
else
    echo "File '$file_name' not found."
fi