#!/usr/bin/env fish

# This script is used to update all git repositories in a given directory
function check_repos
    argparse --name=check_repos 'h/help' 'g/git_dir=' -- $argv
    or return

    if set -q _flag_h
        echo "Usage: check_repos [-g|--git-dir <git-dir>] [<repositories>]"
        return 0
    end

    if set -q _flag_g
        set GIT $_flag_g
    else
        set GIT $HOME/git
    end

    if test -n "$argv"
        set old_repos $argv
    else
        set old_repos CGAL-matlab ProVANT-Simulator_Developer algortihmns armadillo-pmr cpp_tests data_structures dotfiles matlab-dev nmpc-obs ocpsol pres-research prov_sim_configs pylattes reports papers scripts sets-obs svgs test thesis
        # set repos (echo ""$repos |  sed -e 's#\([a-zA-Z\._0-9\-]\+\)#/home/gagarin/git/\1#g')
    end
    set n (count $old_repos)
    set repos
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

    set pwd $(pwd)

    if set -q _flag_r_
        set dirs

        set dir
        set n (count $repos)
        for i in (seq 1 $n)
            if not test -d $repos[$i]
                set -e repos[$i]
            else
                continue
            end
        end
    else
        set dirs $(fd . -td $GIT -d1)
    end

    if test -z "$repos"
        echo "No repos found"
        return 1
    else
        echo "Found "$(count $repos)" repositories"
    end

    set dirty
    for repo in $repos
        cd $repo
        if not is_git_repo
            continue
        end

        if clean
            # behind && echo "git pull $repo"
            # ahead && echo "git push $repo"
            if behind
                echo ''
                echo "git pull $repo"
                git pull
            end
            if ahead
                echo ''
                echo "git push $repo"
                git push
            end
        else 
            set repo_name $(basename $repo)
        
            if notstaged || untracked
                echo ''
                echo "repo $repo_name has uncommited changes"
                set -a dirty $dirty
            end
        end
    end

    if test -z "$dirty"
        echo ''
        echo "All repos are up to date"
    else
        echo ''
        echo 'dirty repos:'
        echo "$dirty" | sed -e 's/ /\n/g'
    end

    echo ''
    # echo "dirty repos: $dirty"
    cd "$pwd"
end


function update_ufmg
    set GIT $HOME/git
    set repos CGAL-matlab ProVANT-Simulator_Developer algortihmns armadillo-pmr cpp_tests data_structures dotfiles matlab-dev nmpc-obs ocpsol pres-research prov_sim_configs pylattes reports papers scripts sets-obs svgs test thesis
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
