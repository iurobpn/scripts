#!/bin/bash

# Destination path for rsync
DEST_PATH="/var/lib/gitea/data/gitea-repositories/gagarin/"

# Check if the filename is provided as an argument
if [[ -z "$1" ]]; then
  echo "Usage: $0 <file_with_repository_list>"
  exit 1
fi

# Path to the file containing the list of folders
REPO_LIST_FILE="$1"

# Check if the file exists
if [[ ! -f "$REPO_LIST_FILE" ]]; then
  echo "Error: File $REPO_LIST_FILE not found."
  exit 1
fi

# Read each line in the file
while IFS= read -r folder || [[ -n "$folder" ]]; do
  # Skip empty lines
  if [[ -z "$folder" ]]; then
    continue
  fi

  # Check if the folder exists
  if [[ ! -d "$folder" ]]; then
    echo "Skipping: $folder does not exist or is not a directory."
    continue
  fi

  # Check if the folder is a Git repository
  if [[ -d "$folder/.git" ]]; then
    echo "Processing: $folder is a valid Git repository."

    # Run rsync with sudo
    sudo rsync -azvhP "$folder" "$DEST_PATH"
  else
    echo "Skipping: $folder is not a Git repository."
  fi

done < "$REPO_LIST_FILE"

# Print completion message
echo "All repositories processed."

