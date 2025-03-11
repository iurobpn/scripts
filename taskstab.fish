function taskstab
    if not test -z $argv && test $argv[1] = "-h"

        echo "Usage: taskstab"
        echo "    Open a new zellij tab with a layout with vit and a pane to run"
        echo "    taskwarrior commands."
        return
    end
    # echo $notes_dir
    # cd $notes_dir
    if zellij action query-tab-names | grep tasks
        zellij action go-to-tab-name tasks
    else
        zellij action new-tab --layout taskstab --name tasks
    end
end

