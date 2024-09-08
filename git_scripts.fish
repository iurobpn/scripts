
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
