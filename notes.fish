function notes
    if test -z "$argv"
        set notes_dir $HOME/sync/obsidian
    else
        set notes_dir $argv
    end
    # echo $notes_dir
    # cd $notes_dir
    if zellij action query-tab-names | grep notes
        zellij action go-to-tab-name notes
    else
        zellij action new-tab --layout notes.kdl --name notes --cwd "$NOTES_DIR"
    end
end

