function taskswin
    if test -n "$argv" && test "$argv[1]" = "-h"

        echo "Usage: taskstab"
        echo "    Open a new zellij tab with a layout with vit and a pane to run"
        echo "    taskwarrior commands."
        return
    end
    # echo $notes_dir
    # cd $notes_dir
    tmux-attach-or-create tasks && tmux send-keys Escape i "vit" Enter
end

