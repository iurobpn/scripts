
function fzfbranch
    git branch | sed 's/^[* ] //' | fzf --reverse --preview-window='down:80%'  --preview 'git log --oneline --color=always $(echo {} | awk "{print \$1}")' | xargs git checkout
end

function fzfgit_file_history
    git log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short --no-color -- $argv | fzf --reverse --preview 'git log -n 1 --stat --color=always $(echo {2} | awk "{print \$1}")'
end

function fzfgit_function_history
    git log --oneline --graph --date=short --no-color -- -L$argv | fzf --reverse --preview 'git log -n 1 --stat --color=always $(echo {} | awk "{print \$1}")' --ansi
end

function fzfcommit
    git log --oneline | fzf --reverse --preview 'git log -n 1 --stat --color=always $(echo {} | awk "{print \$1}")' --ansi
end

function search_tasks
    argparse --name=search_tasks 'h/help' 'w' 'f/finished' 'n/not-started' 'd/dir=' -- $argv
    # Process options
    set -l options
    if set -q _flag_w
        set -a options '-w'
        # Work in progress
    else if set -q _flag_f
        # Task done
        set -a options '-f'
    else if set -q _flag_n
        # Task not started
        set -a options '-f'
    else if set -q _flag_h
        echo "Usage: search_tasks [-w] [-f] [-n] [-d directory] [search patterns]"
        return
    else
    # No option specified, search for all tasks
        set -a options '-n'
    end

    if set -q _flag_d
        # Search in the specified directory
        set nodes_dir $_flag_d
        set -a options "-d $_flag_d"
        echo "Searching in $_flag_d"
    end
    # Any remaining arguments are treated as search patterns (hashtags or other filters)
    set search_args $argv

    find_tasks $options | fzf --reverse --preview 'bat --style=numbers --color=always --theme=gruvbox-dark --highlight-line=$(echo {} | cut -d: -f2) $(echo {} | cut -d: -f1)' --ansi
end

function get_refs
    if test -z $argv
        set refs "refs/heads/"
    else
        set refs "refs/$argv"
    end
    git for-each-ref --format='%(refname:short) %(upstream:short)' $refs
end


function get_branches
    if test -z $argv
        set refs "refs/heads/"
    else
        if test $argv = "all"
            set refs "refs/"
        else if test $argv = "remote"
            set refs "refs/remotes/"
        else if test $argv = "local"
            set refs "refs/heads/"
        end
    end
    git for-each-ref --format='%(refname:short)' $refs
end


function get_remote_branches
    get_branches remote | sed 's#\([a-zA-Z]\+\)/\(.*\)#\1 \2#'
end
