
function vf
    test -n "$argv"; and test "argv" = "-h"; and echo "Usage: vf [query_dir]\n searchs in subdirectory of query_dir to for files to open in vim"; and return
    set -l dir
    if test -n "$argv"
        set dir $argv[1]
    end
    if test -z "$dir"
        set -e dir
    end
    fd . --hidden -tf --exclude=.git $dir |  sed -e "s#^\./(.*)##g" | fzf --multi $FZF_DEFAULT_OPTIONS --bind "enter:become(nvim {+})" --preview "bat --style=numbers --color=always {}" --preview-window "60%,wrap"
end

function lgf
    gita ll 2> /dev/null | \
        awk '!/\[\$?\]/' | \
        fzf --tmux $FZF_DEFAULT_OPTIONS --ansi | \
        cut -d" " -f1 | \
        xargs -n1 gita lg 2> /dev/null
end

function frg
    set rg_prefix "rg --column --line-number --no-heading --color=always --smart-case";
    fzf --bind "start:reload:$rg_prefix {q}" \
    --bind "change:reload:$rg_prefix {q} || true" \
    --bind 'enter:become(vim {1} +{2})' \
    --ansi --disabled \
    --height=50% --layout=reverse
end

function frg2
# 1. Search for text in files using Ripgrep
# 2. Interactively restart Ripgrep with reload action
# 3. Open the file in Vim
set RG_PREFIX "rg --column --line-number --no-heading --color=always --smart-case "
set INITIAL_QUERY '${*:-}'
fzf --ansi --disabled --query "$INITIAL_QUERY" \
    --bind "start:reload:$RG_PREFIX {q}" \
    --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
    --delimiter : \
    --preview 'bat --color=always {1} --highlight-line {2}' \
    --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
    --bind 'enter:become(vim {1} +{2})'
end

function fprg
    test -n "$argv"; and test "argv" = "-h"; and echo "Usage: fprg [query_dir] [prog]\n searchs in subdirectory of query_dir to run aprog with the selected files as arguemnts"; and return
    if test (count $argv) -ge 1
        set dir $argv[1]
    end
    if test (count $argv) -ge 2
        set prog $argv[2]
    else
        set prog "echo"
    end
    fd . -u -tf "$dir" |  sed -e 's#^\./(.*)##g' | fzf --multi $FZF_DEFAULT_OPTIONS --bind 'enter:become($prog {+})'
end

function zfloat 
    test -n "$argv"; and test "argv" = "-h"; and echo "Usage: zfloat [query_dir]\n searchs a subdirectory of query_dir to enter"; and return
    set dir fcd $argv
    fd . -u -td $dir | fzf $FZF_DEFAULT_OPTIONS
    zellij action new-pane -f  --cwd "$dir" -- fish
end

function gitsearch
    test -n "$argv"; and test "argv" = "-h"; and echo "Usage: git-search [query]\n searchs in git repo for files"; and return
    git ls-files | fzf $FZF_DEFAULT_OPTIONS --query="$argv"
end

function githistory
    test -n "$argv"; and test "argv" = "-h"; and echo "Usage: git-history [query]\n searchs in git repo for files"; and return
    git log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short | fzf $FZF_DEFAULT_OPTIONS --ansi --preview="echo {} | awk '{print $1}' | xargs git show --color"
end

function gith
    if test -z "$argv"; or test "argv" = "-h"; 
        echo "Usage: gith [query]\n searchs in git repo for files"; 
        return
    end
    git log -S "$argv" --pretty=format:'%C(auto)%h %s %C(black)%C(bold)%an %C(green)%C(bold)%cr' | \
fzf --ansi --no-sort --preview="echo {} | cut -d' ' -f1 | xargs -I {} git show --color=always {}"
end

function fcd
    test -n "$argv"; and test "argv" = "-h"; and echo "Usage: fcd [query_dir]\n enters the selected directory"; and return
    set dir (fscd $argv)
    echo $dir
    if test -n "$dir"
        cd $dir
    end
end

# fzf with preview for results with format file:line: ...
function agf
    test -n "$argv"; and test "argv" = "-h"; and echo "Usage: fzp [query_dir]\n searchs in subdirectory of query_dir to for files to open in vim"; and return

    ag $argv |  fzf --multi $FZF_DEFAULT_OPTIONS --bind 'enter:become(vim {+})' --preview 'bat --style=numbers --color=always --theme=gruvbox-dark --highlight-line=$(echo {} | cut -d: -f2) $(echo {} | cut -d: -f1)' --ansi
    cd -
end

# fscd query_dir
# returns the selected directory
function fscd
    test -n "$argv"; and test "argv" = "-h"; and echo "Usage: fscd [query_dir]\n returns the selected directory"; and return
        
    set dir $(fd . -u -td $argv | fzf $FZF_DEFAULT_OPTIONS)
    if test -n "$dir"
        echo $dir
    end
end

# fzz query
# search in z.lua lists and cd to the selected directory
function fzz
    test -n "$argv"; and test "argv" = "-h"; and echo "Usage: fzz [query_dir]\nsearch in query in z.lua history db and enters the selected dir"; and return
    set dir $(z -l $argv | fzf $FZF_DEFAULT_OPTIONS | awk '{print $2}')
    if test -n "$dir"
        cd $dir
    end
end

# # fbr - checkout git branch (including remote branches)
# function fbr
#     set -l branches=$(git branch --all | grep -v HEAD) &&
#     set -l branch=$(echo "$branches" |
#     fzf -d $(( 2 + (wc -l <<< "$branches") )) +m) &&
#     git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
# end
#


# fco - checkout git branch/tag
function fco
    set -l branches $(git --no-pager branch --all --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" | sed '/^$/d')
    set -l tags $(git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}')
    set -l target $(echo "$branches"; echo "$tags") | fzf --no-hscroll --no-multi -n 2 --ansi or return
    git checkout $(echo $target | awk '{print $2}')
end

# fco_preview - checkout git branch/tag, with a preview showing the commits between the tag/branch and HEAD
# function fco_preview
#     set -l branches $(git --no-pager branch --all --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" | sed '/^$/d') 
#     set -l tags $(git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}') 
#     set -l target $(echo "$branches"; echo "$tags") | fzf --no-hscroll --no-multi -n 2 --ansi --preview="git --no-pager log -150 --pretty=format:%s '..{2}'") or return
#     git checkout $(echo $target | awk '{print $2}')
# end
#

function vgith
    if test -z "$argv"; or test "argv" = "-h"; 
        echo "Usage: vgith [query]\n searchs in git repo for files"; 
        return
    end
    echo "$argv"
    git log --pretty=format:'%h %s %C(green)(%cr) %C(blue)<%an>%C(reset)' -G "$argv" | fzf --ansi --no-sort --multi --preview="echo {} | cut -d' ' -f1 | xargs -I {} git show --color=always {}" --bind 'enter:execute(echo {} | cut -d" " -f1 | xargs -I {} sh -c "git show {}" | vim -)'
    # git log --pretty=format:'%h %s %C(green)(%cr) %C(blue)<%an>%C(reset)' -S "$argv" | \
    # fzf --multi --ansi --no-sort --preview='echo {} | cut -d" " -f1 | sed -e "s/^([a-z0-9]\+) .*/\1/g" | xargs -I {} git show --color=always {}' --bind 'enter:execute(vim <(git show {+}))'
end
