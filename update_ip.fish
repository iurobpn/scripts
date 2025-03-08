#!/usr/bin/fish

function update_ip
    if not set -q SYNC_PATH
        set -xg SYNC_PATH ~/sync
    end
    cp ~/.ssh/config ~/.ssh/config.bkp
    update_ip.awk $SYNC_DIR/kpxc/ip.md ~/.ssh/config > /tmp/config \
    && cp /tmp/config ~/.ssh/config
end

function updateip
    if not set -q SYNC_PATH
        set -xg SYNC_PATH ~/sync
    end
    update_ip.awk $SYNC_PATH/kpxc/ip.md ~/.ssh/config
end

function myip
    curl -4 icanhazip.com
end

