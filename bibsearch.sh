#!/usr/bin/bash

# Ensure a file is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 file.bib"
    exit 1
fi

BIBFILE="$1"

# Check if required tools are installed
if ! command -v fzf &>/dev/null; then
    echo "fzf is required but not installed. Install it first."
    exit 1
fi

if ! command -v bat &>/dev/null; then
    echo "bat is required but not installed. Install it first."
    exit 1
fi

# Extract whole BibTeX entries, separating them with a placeholder
extract_entries() {
    awk 'BEGIN { RS="\n@"; ORS="\n\n\0" } NR>1 { print "@"$0 }' "$BIBFILE"
}

# Use fzf to search, treating each whole entry as a single item
# selected_entries=$(extract_entries | fzf --read0 --multi --preview "echo {} | bat")
selected_entries=$(extract_entries | fzf --read0 --multi --preview "echo {} | bat --style=grid --language=bibtex")

# Print the selected entries, formatting with bibtool if available
if [[ -n "$selected_entries" ]]; then
    if command -v bibtool &>/dev/null; then
        echo "$selected_entries" | bibtool -s
    else
        echo "$selected_entries"
    fi
fi

