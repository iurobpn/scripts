#!/usr/bin/fish

function jqp
    if [ -z "$argv" ]
        echo 'usage: jqp <file>'
        exit 0
    end
 
    echo '' | fzf --print-query --preview "cat $argv | jq {q}"
end
