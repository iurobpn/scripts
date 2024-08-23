#!/usr/bin/fish

if test (count $argv) -ne 2
    echo "Usage: grid.fish <path> <filename>"
    exit 1
end
set -xg cwd $argv[1]
set -xg fname $argv[2]


echo "layout { 
    pane split_direction="vertical" {
        pane cwd=\"$cwd\"
        pane cwd=\"$cwd\"
    }
    pane split_direction="vertical" {
        pane cwd=\"$cwd\"
        pane cwd=\"$cwd\"
    }
}" > $fname

