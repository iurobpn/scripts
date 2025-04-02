function notes
    if test -n "$argv" && test "$argv[1]" = "-h"
        if not set -q PKM_DIR
            set -gx PKM_DIR ~/git/pkm
        end

        echo "Usage: notes [notes_dir]"
        echo "Open a new zellij tab with the notes layout."
        echo "If notes_dir is not provided, it defaults to $PKM_DIR."
        return
    end
    if test -z "$argv"
        set notes_dir $PKM_DIR
    else
        set notes_dir $argv
    end
    # echo $notes_dir
    # cd $notes_dir
    if tmux-has-window notes
        tmux-goto-window notes
    else
        tmux new-window -n notes -c $notes_dir
    end
end

