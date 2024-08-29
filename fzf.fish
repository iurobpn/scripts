
function vf
    fd . -tf "$argv" |  sed -e 's#^\./(.*)##g' | fzf --multi $FZF_DEFAULT_OPTIONS --bind 'enter:become(vim {+})'
end

function fprg
    if test (count $argv) -ge 1
        set dir $argv[1]
    end
    if test (count $argv) -ge 2
        set prog $argv[2]
    end
    fd . -tf "$dir" |  sed -e 's#^\./(.*)##g' | fzf --multi $FZF_DEFAULT_OPTIONS --bind 'enter:become($prog {+})'
end

function zfloat 
    set dir fcd $argv
    fd . -td $dir | fzf $FZF_DEFAULT_OPTIONS
    zellij action new-pane -f  --cwd "$dir" -- fish
end

function fcd
    fscd $argv | xargs cd
end

function fscd
    set dir $(fd . -td $argv | fzf $FZF_DEFAULT_OPTIONS)
    if test -n "$dir"
        echo $dir
    end
end

function fzz
    set dir $(z -l $argv | fzf $FZF_DEFAULT_OPTIONS | awk '{print $2}')
    if test -n "$dir"
        cd $dir
    end
end

function find_tasks
    ag  '\- \[.\]' | cut -d : -f1,2 | sed 's/:/ /g' | sort | uniq
end

