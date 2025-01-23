#!/bin/bash
# Destination path for rsync
DEST_PATH="/var/lib/gitea/data/gitea-repositories/gagarin/"

# Rename folders in the destination path that do not end with .git
for folder in "$DEST_PATH"*; do
    if [[ -d "$folder" && ! "$folder" == *.git  ]]; then
        mv "$folder" "$folder.git"
        echo "Renamed $folder to $folder.git"
    fi
done
