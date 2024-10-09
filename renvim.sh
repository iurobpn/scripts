#!/bin/bash

# check for link in args
if [ -z "$1" ]; then
    wget https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz
else
    wget $1
fi 
rm -rf /opt/nvim-linux64
tar -xvf nvim-linux64.tar.gz -C /opt
rm nvim-linux64.tar.gz
