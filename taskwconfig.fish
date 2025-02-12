#!/usr/bin/fish
set -l TW_DIR /home/gagarin/sync/taskw/

rsync -azvhP /home/gagarin/.task $TW_DIR
cp /home/gagarin/.taskrc $TW_DIR
