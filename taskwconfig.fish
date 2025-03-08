#!/usr/bin/fish

function twsync
    if [ -z "$argv" ]
        echo "Usage: tasksync <tosync|tohome>"
        return
    else
        set -l SYNC_DIR $HOME/sync/taskw/
        if [ $argv[1] = "tohome" ]
            set FROM $SYNC_DIR
            set TO $HOME
        else if [ $argv[1] = "tosync" ]
            set FROM $HOME
            set TO $SYNC_DIR
        else
            echo "Usage: taskwconfig.fish <tosync|tohome>"
            return
        end

        rsync -azvhP $FROM/.task $TO
        cp -v $FROM/.taskrc $TO
    end
end
