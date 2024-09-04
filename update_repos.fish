#!/usr/bin/env fish

# This script is used to update all git repositories in a given directory
function check_repos
    argparse --name=check_repos 'h/help' 'g/git_dir=' -- $argv
    or return

    if set -q _flag_h
        echo "Usage: check_repos [-g|--git-dir <git-dir>] [<repositories>]"
        return 0
    end

	set -l GIT
    if set -q _flag_g
        set GIT $_flag_g
    else
        set GIT $HOME/git
    end

	set -l old_repos
    if test -n "$argv"
        set old_repos $argv
    else
        set old_repos CGAL-matlab ProVANT-Simulator_Developer armadillo-pmr cpp_tests data_structures dotfiles matlab-dev nmpc-obs ocpsol pres-research prov_sim_configs pylattes reports papers scripts sets-obs svgs thesis
        # set repos (echo ""$repos |  sed -e 's#\([a-zA-Z\._0-9\-]\+\)#/home/gagarin/git/\1#g')
    end
    set -l n (count $old_repos)
    set -l repos
    echo "Checking repositories:"
    for i in (seq 1 $n)
        if test -d "$GIT/$old_repos[$i]"
            set -a repos "$GIT/$old_repos[$i]"
        else
            echo "repo $old_repos[$i] not found"
        end
    end
    echo 'checking finished'
    echo ''

    set -l pwd $(pwd)

    if set -q _flag_r_
        set -l dirs

        set -l dir
        set -l n (count $repos)
        for i in (seq 1 $n)
            if not test -d $repos[$i]
                set -e repos[$i]
            else
                continue
            end
        end
    else
        set -l dirs $(fd . -td $GIT -d1)
    end

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

        git fetch origin --quiet
        set -l bstatus (branch_status)
        set -l current_branch (get_current_branch)
        for line in $bstatus
            # echo "-------------- branch status loop ---------------------------"
            set -l nahead (echo $line | get_n_ahead)
            set -l nbehind (echo $line | get_n_behind)
            set -l local_branch (echo $line | get_local_branch)
            set -l remote (echo $line | get_remote_from_branch_status)
            # echo "-------------- debug info ---------------------------"
            # echo "n_ahead: $nahead"
            # echo "n_behind: $nbehind"
            # echo "local_branch: $local_branch"
            # echo "remote: $remote"
            # echo "current_branch: $current_branch"
            # echo "------------- end of debug info ---------------------"

            if [ $remote = 'origin' ]
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
                        echo "git pull origin $local_branch"
                        sync_repo pull origin $local_branch
                    end
                else 
                    set -l repo_name $(basename $repo)

                    if notstaged || untracked
                        echo ''
                        echo "repo $repo_name has uncommited changes"
                        set -al dirty $dirty
                    end
                end
                if test $nahead -gt 0
                    echo ''
                    echo "git push origin $local_branch"
                    # set -l cur_branch (get_current_branch)
                    # echo "current branch (nahead if): $cur_branch"
                    sync_repo push origin $local_branch
                end
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
end

function sync_repo
    if test (count $argv) -lt 3
        echo "Usage: sync_repo <command> <remote> <repo>"
        return 1
    end
    set cur_branch $(get_current_branch)
    set cmd $argv[1]
    set branch $argv[3]
    set remote $argv[2]
	
	# echo "current branch: $current_branch"
	# echo "branch: $branch"
	# echo "remote: $remote"
	# echo "cmd: $cmd"

    if [ $cur_branch != $branch ]
        git checkout $branch --quiet
    end

    git $cmd $remote $branch

    if [ $cur_branch != $branch ]
        git checkout --quiet -
    end
end

function update_ufmg
    set -l GIT $HOME/git
    set -l repos CGAL-matlab ProVANT-Simulator_Developer armadillo-pmr cpp_tests data_structures dotfiles matlab-dev nmpc-obs ocpsol pres-research prov_sim_configs pylattes reports papers scripts sets-obs svgs thesis
    # set repos (echo $repos |  sed -e 's#\([a-zA-Z\._0-9\-]\+\)#/home/gagarin/git/\1#g')
    # echo "updating repos: $repos"
    check_repos $repos
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

