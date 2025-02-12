function notes
    if [ $argv[1] == "-h" ]
        echo "Usage: notes [notes_dir]"
        echo "Open a new zellij tab with the notes layout."
        echo "If notes_dir is not provided, it defaults to $HOME/sync/obsidian."
        return
    end
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
        zellij action new-tab --layout notes --name notes --cwd "$NOTES_DIR"
    end
end

