#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 file.bib"
    exit 1
fi

args=$@
if echo "$*" | grep ' -p'; then
    print=1
    args=( "${args[@]/ -p/}" )
else
    print=0
fi
# Ensure a file is provided

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
selected_entries=$(extract_entries | fzf --read0 --multi --preview "echo {} | bat --wrap=character  --language=bibtex --style=plain")

# Print the selected entries, formatting with bibtool if available
if [[ -n "$selected_entries" ]]; then
    if [ $print -eq 1 ]; then
        echo "$selected_entries" | bibtool -s
    else
        echo "$selected_entries"
    fi
fi
