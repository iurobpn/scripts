#!/usr/bin/fish

# by http://github.com/jehiah
# this prints out some branch status (similar to the '... ahead' info you get from git status)

# example:
# $ git branch-status
# dns_check (ahead 1) | (behind 112) origin/master
# master (ahead 2) | (behind 0) origin/master
function branch_status
    git for-each-ref --format="%(refname:short) %(upstream:short)" refs/heads | \
    while read local remote
        if test -z "$remote"
            continue
        end
        git rev-list --left-right "$local...$remote" -- 2>/dev/null >/tmp/git_upstream_status_delta
        or continue
        set LEFT_AHEAD (grep -c '^<' /tmp/git_upstream_status_delta)
        set RIGHT_AHEAD (grep -c '^>' /tmp/git_upstream_status_delta)
        echo "$local (ahead $LEFT_AHEAD) | (behind $RIGHT_AHEAD) $remote"
    end
end

function get_info
    set -l bs (branch_status)

    if test -z "$bs"
        "No branch results detected"
    end

    for b in $bs
        set -l local_branch (echo $b | get_local_branch)
        echo 'local branch: ' $local_branch
        set -l remote_branch (echo $b | get_remote_branch)
        echo 'remote branch: ' $remote_branch
        set -l ahead (echo $b | get_n_ahead)
        echo 'ahead: ' $ahead
        set -l behind (echo $b | get_n_behind)
        echo 'behind: ' $behind
        echo '-------'
        # echo $b
    end
end

function get_local_branch
    sed 's/^\([a-zA-Z0-9._\/-]\+\).*/\1/' $argv  # get current local branch
end


function get_n_ahead
    sed 's/.*(ahead \([0-9]\+\)).*/\1/' $argv  # get ahead number of commits
end

function get_n_behind
    sed 's/.*(behind \([0-9]\+\)).*/\1/' $argv # get behind number of commits
end

function get_remote_branch
    sed 's#^.*) \([a-zA-Z0-9._\/-]\+\)/\([a-zA-Z0-9._\/-]\+\) *.*#\1 \2#' $argv # get remote/branch info
end

function get_remote_from_branch_status
    get_remote_branch | sed 's/\([a-zA-Z0-9._\/-]\+\) [a-zA-Z0-9._\/-]\+/\1/' $argv # get remote
end

function get_remotes
    echo (git remote)
end

function get_current_branch
    git status -sb | sed -n '1s/## \([a-zA-Z0-9._\/-]\+\)\.\.\..*$/\1/p'
end

