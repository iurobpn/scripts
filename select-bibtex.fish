#!/usr/bin/env fish

function bibtex-sel
    # Check if a file is provided
    if test (count $argv) -ne 1
        echo "Usage: bibtex-select <bibtex-file>"
        exit 1
    end

    set bibfile $argv[1]

    # Check if the file exists
    if not test -f $bibfile
        echo "File not found: $bibfile"
        exit 1
    end

    # Read the BibTeX file and extract entries
    set entries (awk '/^@/ {print $0}' $bibfile | fzf --multi --preview "awk -v entry={} '/^@/ {p=0} {if (\$0 ~ entry) p=1} p' $bibfile")

    # Output the selected entries
    for entry in $entries
        awk -v entry=$entry '/^@/ {p=0} {if ($0 ~ entry) p=1} p' $bibfile
    end

end

function bib-sel
    # Check if a file is provided
    if test (count $argv) -ne 1
        echo "Usage: bibtex-select <bibtex-file>"
        exit 1
    end

    set bibfile $argv[1]

    # Check if the file exists
    if not test -f $bibfile
        echo "File not found: $bibfile"
        exit 1
    end

    # Read the BibTeX file and extract entries
    set entries (awk '/^@/ {print $0}' $bibfile | fzf --multi --preview "awk -v entry={} '/^@/ {p=0} {if (\$0 ~ entry) p=1} p' $bibfile")

    # Output the selected entries
    for entry in $entries
        awk -v entry=$entry '/^@/ {p=0} {if ($0 ~ entry) p=1} p' $bibfile
    end

end
