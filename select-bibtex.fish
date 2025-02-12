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

function bibsel
    # Check if a file is provided
    if test (count $argv) -ne 1
        echo "Usage: bibsel <bibtex-file>"
        exit 1
    end

    set bibfile $argv[1]

    # Check if the file exists
    if not test -f $bibfile
        echo "File not found: $bibfile"
        exit 1
    end

    # Extract entries and their citation keys
    set entries_with_keys (awk '
    BEGIN { FS="\n"; RS="\n\n" }
    /^@/ {
    entry_key = $1
    gsub(/^@[^{]*{/, "", entry_key)
    gsub(/,$/, "", entry_key)
    print $0 " | " entry_key
    }
    ' $bibfile)

    # Use fzf to select entries
    set selected_entries (echo $entries_with_keys | fzf --multi --delimiter="|" --with-nth=1 --preview-window="right,10%" --preview "echo {2}")

    # Output the selected entries
    for entry in $selected_entries
        set entry_content (echo $entry | awk -F"|" '{print $1}' | string trim)
        echo $entry_content
    end
end
