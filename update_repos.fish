#!/usr/bin/env fish

function check_repos
    set GIT $HOME/git
    set pwd $(pwd)

    if test -n "$argv"
        set dirs ''
        set args (string split ' ' $argv)
        # echo 'checking args:'

        for arg in $args
            set dir (fd . -td -d1 $GIT | sed -e 's/ /\n/g' | grep "$arg")
            set dirs "$dirs $dir"
        end
    else
        set dirs $(fd . -td $GIT -d 1)
    end

    if test -z "$dirs"
        echo "No repos found"
        return 1
    end
    set repos

    set dirs (string split ' ' $dirs)
    

    for repo in $dirs
        if test -d $repo
            cd $repo
            if not is_git_repo
                continue
            end
        else
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
                echo ' '
                echo "repo $repo_name has uncommited changes"
                set dirty "$dirty $repo_name"
            end
        end
    end

    echo ' '
    # echo "dirty repos: $dirty"
    cd "$pwd"
end


function update_ufmg
    set GIT $HOME/git
    set repos "CGAL-matlab ProVANT-Simulator_Developer algortihmns armadillo-pmr cpp_tests data_structures dotfiles matlab-dev nmpc-obs ocpsol pres-research prov_sim_configs pylattes reports papers scripts sets-obs svgs test thesis"
    set repos (echo $repos |  sed -e 's#\([a-zA-Z\._0-9\-]\+\)#/home/gagarin/git/\1#g')
    # echo "updating repos: $repos"
    check_repos "$repos"
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
