#!/bin/bash

# Check if both files are provided as arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 file1 file2"
    exit 1
fi

file1="$1"
file2="$2"

# Use awk to remove lines from file1 that are in file2
awk 'NR==FNR {lines[$0]=0; next} !($0 in lines)' "$file2" "$file1"
