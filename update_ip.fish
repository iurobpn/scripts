#!/usr/bin/fish

function update_ip
    cp ~/.ssh/config ~/.ssh/config.bkp
    update_ip.awk ~/sync/obsidian/ip.md ~/.ssh/config > /tmp/config \
    && cp /tmp/config ~/.ssh/config
end

function updateip
    update_ip.awk ~/sync/obsidian/ip.md ~/.ssh/config
end

function myip
    curl -4 icanhazip.com
end

