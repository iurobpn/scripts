#!/usr/bin/env fish

# This script is used to update all git repositories in a given directory
function check_repos
    argparse --name=check_repos 'h/help' 'g/git_dir=' 'r/remote=' -- $argv
    or return
    set pwd $(pwd)

    set pwd $(pwd)
    echo "pwd: $pwd"
    if set -q _flag_h
        echo "Usage: check_repos [-g|--git-dir <git-dir>] [-r|--remote <remote_name>] [<repositories>]"
        return 0
    end

    set -l GIT
    if set -q _flag_g
        set GIT $_flag_g
    else
        set GIT $HOME/git
    end

    set -l remote
    if set -q _flag_r
        set remote $_flag_r
    else
        set remote origin
    end

    set -l old_repos
    if test -n "$argv"
        set old_repos $argv
    else
        cd $GIT
        set old_repos (fd . --relative-path -td -d1)
    end
    set n (count $old_repos)
    set repos
    echo "Checking repositories:"
    for i in (seq 1 $n)
        if test -d "$GIT/$old_repos[$i]"; and check_remote $remote "$GIT/$old_repos[$i]"

            set -a repos "$GIT/$old_repos[$i]"
        else
            echo "repo $old_repos[$i] not found"
        end
    end
    echo 'checking finished: '(count $repos)' repos found'
    echo ''


    set -l dirs $(fd . -td $GIT -d1)

    if test -z "$repos"
        echo "No repos found"
        return 1
    else
        echo "Found "$(count $repos)" repositories"
    end

    set -l dirty
    for repo in $repos
        cd $repo

        if not is_git_repo
            continue
        end

        echo ''
        echo "-------- Checking repo $repo  ----------"

        git fetch $remote --quiet
        set -l bstatus (branch_status)
        set -l current_branch (get_current_branch)
        for line in $bstatus
            # echo "-------------- branch status loop ---------------------------"
            set -l nahead (echo $line | get_n_ahead)
            set -l nbehind (echo $line | get_n_behind)
            set -l local_branch (echo $line | get_local_branch)
            # set -l remote (echo $line | get_remote_from_branch_status)
            # echo "-------------- debug info ---------------------------"
            # echo "n_ahead: $nahead"
            # echo "n_behind: $nbehind"
            # echo "local_branch: $local_branch"
            # echo "remote: $remote"
            # echo "current_branch: $current_branch"
            # echo "------------- end of debug info ---------------------"

            if clean
                # behind && echo "git pull $repo"
                # ahead && echo "git push $repo"
                if test $nbehind -gt 0
                    echo ''
                    # set -l cur_branch (get_current_branch)
                    # echo "current branch (nbehind if): $cur_branch"
                    # if [ "$cur_branch" !=  "$local_branch" ]
                    #     # echo "cur_branch != local_branch"
                    #     git checkout $local_branch
                    # end
                    echo "git pull $remote $local_branch"
                    sync_repo pull $remote $local_branch
                end
            else 
                set -l repo_name $(basename $repo)

                if notstaged || untracked
                    echo ''
                    echo "repo $repo_name has uncommited changes"
                    set -a dirty $repo
                end
            end
            if test $nahead -gt 0
                echo ''
                echo "git push $remote $local_branch"
                # set -l cur_branch (get_current_branch)
                # echo "current branch (nahead if): $cur_branch"
                sync_repo push $remote $local_branch
            end

            # echo ''
            # echo '---------- end of branch status loop -----------------'

        end
        # echo '-------- end of repo loop -----------------'
    end

    if test -z "$dirty"
        echo ''
        echo "All repos are clean"
    else
        echo ''
        echo 'dirty repos: '
        echo "$dirty" | sed -e 's/ /\n/g'
    end

    echo ''
    # echo "dirty repos: $dirty"
    cd "$pwd"
    echo "pwd: $(pwd)"
end

#check if a remote <remote> exists
function check_remote
    set -l remote $argv[1]
    set -l repo $argv[2]
    set -l pwd $(pwd)

    if not test -d "$repo"
        set repo $HOME/git/$repo
    end
    if not test -d "$repo"
        echo "repo $repo not found"
        return 1
    end
    cd "$repo"
    git remote | grep $remote > /dev/null
end

# Add remotes to newly create bare repositories in $HOME/git/bare
# cloned from $HOME/git/<repo> where <repo> is the name of the repository
#
function add_remotes
    set -l pwd (pwd)
    set -l GIT $HOME/git

    source $GIT/scripts/scripts.fish
    set -l BARE $GIT/bare
    set -l repos $argv

    if test -z "$repos"
        echo "Usage: add_remotes <repo1> <repo2> ..."
        exit 1
    end
    for repo in $repos
        cd "$GIT/$repo"
        set -l remote_dir "$BARE/$repo.git"
        echo "Checking for $remote_dir"
        if test -d "$remote_dir"
            if check_remote "bare" "$repo"
                if git remote set-url bare "$remote_dir" 
                    echo "git remote set-url bare $remote_dir"
                else
                    echo "git remote set-url bare $remote_dir failed"
                end
            else
                if git remote add bare "$remote_dir"
                    echo "git remote add bare $remote_dir"
                else
                    echo "git remote add bare $remote_dir failed"
                end
            end
        else
            echo "No bare repository found for $repo"
        end
    end
    # ls $BARE
    cd "$pwd"
end

function sync_repo
    if test (count $argv) -lt 3
        echo "Usage: sync_repo <command> <remote> <branch>"
        return 1
    end
    set -l cur_branch $(get_current_branch)
    set -l cmd $argv[1]
    set -l remote $argv[2]
    set -l branch $argv[3]
	
	# echo "current branch: $current_branch"
	# echo "branch: $branch"
	# echo "remote: $remote"
	# echo "cmd: $cmd"

    if [ "$cur_branch" != "$branch" ]
        git checkout $branch --quiet
    end

    git $cmd $remote $branch

    if [ "$cur_branch" != "$branch" ]
        git checkout --quiet -
    end
end

function update_ufmg
    argparse --name=check_repos 'r/remote=' -- $argv
    set -l remote
    if set -q _flag_r
        set remote $_flag_r
    else
        set remote origin
    end
    set -l GIT $HOME/git
    set -l repos CGAL-matlab ProVANT-Simulator_Developer armadillo-pmr cpp_tests data_structures dotfiles matlab-dev nmpc-obs ocpsol pres-research prov_sim_configs pylattes reports papers scripts sets-obs svgs thesis
    # set repos (echo $repos |  sed -e 's#\([a-zA-Z\._0-9\-]\+\)#/home/gagarin/git/\1#g')
    # echo "updating repos: $repos"
    check_repos $repos -r $remote
end



function ahead
    git status -sb | grep "ahead" > /dev/null
end

function behind
    git status -sb | grep "behind" > /dev/null
end

function clean
        git status | grep "nothing to commit" > /dev/null
end

function untracked
        git status | grep "Untracked" > /dev/null
end
function notstaged
        git status | grep "not staged" > /dev/null
end

function is_git_repo
    test -d .git
end

