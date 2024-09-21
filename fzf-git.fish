# MIT License (MIT)
#
# Copyright (c) 2024 Junegunn Choi
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Convert bash functions to Fish

function __fzf_git_color
    if set -q NO_COLOR
        echo never
    else if test (count $argv) -gt 0 -a -n "$FZF_GIT_PREVIEW_COLOR"
        echo "$FZF_GIT_PREVIEW_COLOR"
    else
        echo (set -q FZF_GIT_COLOR; and echo $FZF_GIT_COLOR; or echo "always")
    end
end

function __fzf_git_cat
    if set -q FZF_GIT_CAT
        echo "$FZF_GIT_CAT"
        return
    end

    set _fzf_git_bat_options "--style="'${BAT_STYLE:-full}'" --color=(__fzf_git_color .) --pager=never"
    if type -q batcat
        echo "batcat $_fzf_git_bat_options"
    else if type -q bat
        echo "bat $_fzf_git_bat_options"
    else
        echo "cat"
    end
end

function __fzf_git_pager
    set pager (set -q FZF_GIT_PAGER; and echo $FZF_GIT_PAGER; or echo $GIT_PAGER)
    set pager (set -q pager; and echo $pager; or git config --get core.pager 2>/dev/null)
    echo (set -q pager; and echo $pager; or echo "cat")
end

if test (count $argv) -eq 1
    function branches
        git branch $argv --sort=-committerdate --sort=-HEAD --format=$'%(HEAD) %(color:yellow)%(refname:short) %(color:green)(%(committerdate:relative))\t%(color:blue)%(subject)%(color:reset)' --color=(__fzf_git_color) | column -ts$'\t'
    end

    function refs
        git for-each-ref $argv --sort=-creatordate --sort=-HEAD --color=(__fzf_git_color) --format=$'%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)%(color:magenta)remote-branch%(else)%(if:equals=refs/heads)%(refname:rstrip=-2)%(then)%(color:brightgreen)branch%(else)%(if:equals=refs/tags)%(refname:rstrip=-2)%(then)%(color:brightcyan)tag%(else)%(if:equals=refs/stash)%(refname:rstrip=-2)%(then)%(color:brightred)stash%(else)%(color:white)%(refname:rstrip=-2)%(end)%(end)%(end)%(end)\t%(color:yellow)%(refname:short) %(color:green)(%(creatordate:relative))\t%(color:blue)%(subject)%(color:reset)' | column -ts$'\t'
    end

    function hashes
        git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=(__fzf_git_color) $argv
    end

    switch "$argv[1]"
        case branches
            echo 'CTRL-O (open in browser) ╱ ALT-A (show all branches)'
            branches
        case all-branches
            echo 'CTRL-O (open in browser)'
            branches -a
        case hashes
            echo 'CTRL-O (open in browser) ╱ CTRL-D (diff)\nCTRL-S (toggle sort) ╱ ALT-A (show all hashes)'
            hashes
        case all-hashes
            echo 'CTRL-O (open in browser) ╱ CTRL-D (diff)\nCTRL-S (toggle sort)'
            hashes --all
        case refs
            echo 'CTRL-O (open in browser) ╱ ALT-E (examine in editor) ╱ ALT-A (show all refs)'
            refs --exclude='refs/remotes'
        case all-refs
            echo 'CTRL-O (open in browser) ╱ ALT-E (examine in editor)'
            refs
        case nobeep
            # Do nothing
        case '*'
            exit 1
    end
end

# Handle if more than one argument is provided
if test (count $argv) -gt 1
    set branch (git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if test "$branch" = "HEAD"
        set branch (git describe --exact-match --tags 2>/dev/null; or git rev-parse --short HEAD)
    end

    switch "$argv[1]"
        case commit
            set hash (echo $argv[2] | grep -o "[a-f0-9]\{7,\}")
            set path /commit/$hash
        case branch remote-branch
            set branch (echo $argv[2] | sed 's/^[* ]*//' | cut -d' ' -f1)
            set remote (git config branch."$branch".remote; or echo "origin")
            set branch (string replace "$remote/" "" $branch)
            set path /tree/$branch
        case remote
            set remote $argv[2]
            set path /tree/$branch
        case file
            set path /blob/$branch/(git rev-parse --show-prefix)$argv[2]
        case tag
            set path /releases/tag/$argv[2]
        case '*'
            exit 1
    end

    set remote (set -q remote; and echo $remote; or git config branch."$branch".remote; or echo "origin")
    set remote_url (git remote get-url "$remote" 2>/dev/null; or echo "$remote")

    if string match -r "^git@" "$remote_url"
        set url (string replace 'git@' 'https://' (string replace '.git' '' (string replace ':' '/' "$remote_url")))
    else if string match -r "^http" "$remote_url"
        set url (string replace '.git' '' "$remote_url")
    end

    switch (uname -s)
        case Darwin
            open "$url$path"
        case '*'
            xdg-open "$url$path"
    end
    exit 0
end
