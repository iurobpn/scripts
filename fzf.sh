# vim: set ft=bash:

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

function frg {
    export rg_prefix="rg --column --line-number --no-heading --color=always --smart-case"
    fzf --bind "start:reload:$rg_prefix {q}" \
        --bind "change:reload:$rg_prefix {q} || true" \
        --bind 'enter:become(vim {1} +{2})' \
        --ansi --disabled \
        --height=50% --layout=reverse
}

function frg2 {
    # 1. Search for text in files using Ripgrep
    # 2. Interactively restart Ripgrep with reload action
    # 3. Open the file in Vim
    export RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
    export INITIAL_QUERY='${*:-}'
    fzf --ansi --disabled --query "$INITIAL_QUERY" \
        --bind "start:reload:$RG_PREFIX {q}" \
        --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
        --delimiter : \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind 'enter:become(vim {1} +{2})'
}

function fprg {
    [ "argv" = "-h" ] && echo "Usage: fprg [query_dir] [prog]\n searchs in subdirectory of query_dir to run aprog with the selected files as arguemnts"; and return
    dir="$1"
    if [ $# -ge 2 ]; then
        prog=$argv[2]
    else
        prog="echo"
    fi
    fd . -u -tf "$dir" |  sed -e 's#^\./(.*)##g' | fzf --multi $FZF_DEFAULT_OPTIONS --bind 'enter:become($prog {+})'
}

function gitsearch {
    if [ "$1" = "-h" ]; then
        echo "Usage: git-search [query]\n searchs in git repo for files"
        return
    fi
    git ls-files | fzf $FZF_DEFAULT_OPTIONS --query="$*"
}

function githistory {
    if [ "$1" = "-h" ]; then
        echo "Usage: git-history [query]\n searchs in git repo for files"
        return
    fi
    git log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short | fzf $FZF_DEFAULT_OPTIONS --ansi --preview="echo {} | awk '{print $1}' | xargs git show --color"
}
