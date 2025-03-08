#!/usr/bin/fish

function update_ip
    set -l TMP_FILE ~/tmpconf
    update_ip.awk ~/sync/obsidian/ip.md ~/.ssh/config > $TMP_FILE  \
    && mv $TMP_FILE ~/.ssh/config && rm -f $TMP_FILE
end

function myip
    curl -4 icanhazip.com
end

