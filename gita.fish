function gita_sel
    echo "$(gita ls | sed 's/ /\n/g' | fzf | awk 'BEGIN { ORS=" ";} { print }')"
end
