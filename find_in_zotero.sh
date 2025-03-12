#!/bin/bash

fzpdf () {
    fd -e pdf -a | fzf | sed 's/.*/"&"/'
}

fzpdf
