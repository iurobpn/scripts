#!/usr/bin/env fish

set GIT $HOME/git
set dirs $(fd . -td $GIT -d 1)

for repo in $dirs
    cd $repo
    set gs git status > dev/null
    echo $gs | rg "nothing to commit" > /dev/null
    if test $status -eq 0
        set nothing2ci "$nothing2ci $repo"
        set clean 1
    else 
        set clean 0
    end
    echo $gs | rg "Untracked" > /dev/null
    if test $status -eq 0
        set untracked "$untracked $repo"
        set untracked 1
    else
        set untracked 0
    end
    echo $gs | rg "not staged" > /dev/null
    if test $status -eq 0
        set notstaged "$notstaged $repo"
        set notstaged 1
    else
        set notstaged 0
    end
    set gssb git status -sb | /dev/null
    echo $gssb | rg "ahead" > /dev/null
    if test $status -eq 0
        set ahead 1
        git push
    else
        set ahead 0
    end
    echo $gssb | rg "behind" > /dev/null

    if test $status -eq 0
        set behind 1
        git pull
    else
        set behind 0
    end
    
    set pullable 0
    test -n "$clean"; and test -n "$behind"; set pullable 1
    if test $pullable -eq 1
        echo "pulling $repo"
        git pull
    else
        echo "repo $repo has nothing (or cannot) to pull"
    end

    set pushable 0
    test -n "$clean"; and test -n "$ahead"; set pushable 1
    if test $pushable -eq 1
        echo "pushing $repo"
        git push
    else
        echo "repo $repo has nothing (or cannot) to push"
    end

    test -n "$uncommited"
    and echo "repo $repo has uncommited changes"

    test -n "$untracked"
    and echo "repo $repo has untracked files"


end


echo 'Uncommited changes in:'

