#!/usr/bin/fish

function tmux-has-window
    tmux list-windows | grep "\<$argv\>" > /dev/null
end
function tmux-winnr
    tmux list-windows | grep "\<$argv\>" | cut -d":" -f1
end
function tmux-goto-window
    tmux select-window -t (tmux-winnr $argv)
end

function tmux-attach-or-create
    if test -z "$argv"
        echo "tmux-attach-or-creaate: No session name provided"
        return 1
    end
    if tmux-has-window $argv
        tmux-goto-window $argv
    else
        tmux new-window -n $argv
    end
end

function tmux-run
    tmux send -t $argv[1] "$argv[2..-1]" Enter
end

function tmux-vrun
    tmux split -v \; send-keys "$argv" Enter
end

function tmux-hrun
    tmux split -h \; send-keys "$argv" Enter
end
