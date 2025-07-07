#!/bin/bash

# function lgf {
#     fish -C 'lgf';
# }
#
function vf {
    if [ "$1" = "-h" ]; then
        echo "Usage: vf [query_dir]\n searchs in subdirectory of query_dir to for files to open in vim"
        return
    fi
    if [ -n "$1" ]; then
        DIR=$1
    fi
    fd . --hidden -tf --exclude=.git $DIR \
        | sed -e "s#^\./(.*)##g" \
        | fzf   --multi $FZF_DEFAULT_OPTIONS \
                --bind "enter:become(nvim {+})" \
                --preview "bat --style=numbers --color=always {}" \
                --preview-window "60%,wrap"
}

function lgf {
    gita ll 2> /dev/null | \
        awk '!/\[\$?\]/' | \
        fzf --tmux $FZF_DEFAULT_OPTIONS --ansi | \
        cut -d" " -f1 | \
        xargs -n1 gita lg 2> /dev/null
}

