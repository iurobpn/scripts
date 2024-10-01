#!/usr/bin/fish

function update_ip
    update_ip.awk ~/sync/obsidian/ip.md ~/.ssh/config > /tmp/config \
    && mv /tmp/config ~/.ssh/config && rm -f /tmp/config
end

