#!/usr/bin/env fish

function update_ip
    if not set -q SYNC_PATH
        set -xg SYNC_DIRS $HOME/Koofr $HOME/Sync
    end
    set -l MYIP (myip)
    for dir in $SYNC_DIRS
        if test -d $dir
            echo "$MYIP" > $dir/ip.txt
            break
        end
    end
end

function myip
    curl -4 icanhazip.com
end


update_ip

