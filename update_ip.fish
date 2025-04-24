#!/usr/bin/env fish

function update_ip
    if not set -q SYNC_PATH
        set -xg SYNC_DIR $HOME/Koofr
    end
    set -l MYIP (myip)
    echo "$MYIP" > $SYNC_DIR/ip.txt
end

function myip
    curl -4 icanhazip.com
end


update_ip:w

