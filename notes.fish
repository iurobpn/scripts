function notes
    if test -z "$argv"
        set notes_dir $HOME/sync/obsidian
    else
        set notes_dir $argv
    end
    # echo $notes_dir
    cd $notes_dir
    nvim
end
