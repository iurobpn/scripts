function ghce 
    set -l GH_DEBUG "$GH_DEBUG";
    set -l GH_HOST "$GH_HOST";
    set -l FUNCNAME "ghce"
    set -l __USAGE '
    Wrapper around \`gh copilot explain\` to explain a given input command in natural language.

    USAGE
    '"$FUNCNAME"' [flags] <command>

    FLAGS
    -d, --debug      Enable debugging
    -h, --help       Display help usage
    --hostname   The GitHub host to use for authentication

    EXAMPLES

    # View disk usage, sorted by size
    $ '"$FUNCNAME"' "du -sh | sort -h"

    # View git repository history as text graphical representation
    $ '"$FUNCNAME"' "git log --oneline --graph --decorate --all"

    # Remove binary objects larger than 50 megabytes from git history
    $ '"$FUNCNAME"' "bfg --strip-blobs-bigger-than 50M"'

    test -z "$argv"; and echo $__USAGE && return 1;

    argparse 'd/debug' 'h/help' 'hostname=' -- $argv

    if set -q _flag_help
        echo "$__USAGE"
        return 0
    end

    if set -q _flag_debug
        set -g GH_DEBUG "api"
    end

    if set -q _flag_hostname
        set -g GH_HOST "$_flag_hostname"
    end

    # Pass the remaining arguments to the `gh copilot explain` command
    env GH_DEBUG="$GH_DEBUG" GH_HOST="$GH_HOST" gh copilot explain $argv
end

function ghcs
    set TARGET "shell"
    set -l GH_DEBUG "$GH_DEBUG"
    set -l GH_HOST "$GH_HOST"
    set -l FUNCNAME "ghcs"
    set __USAGE '
    Wrapper around \`gh copilot suggest\` to suggest a command based on a natural language description of the desired output effort.
    Supports executing suggested commands if applicable.

    USAGE
    '"$FUNCNAME"' [flags] <prompt>

    FLAGS
    -d, --debug              Enable debugging
    -h, --help               Display help usage
    --hostname           The GitHub host to use for authentication
    -t, --target target      Target for suggestion; must be shell, gh, git
    default: "$TARGET"

    EXAMPLES

    - Guided experience
    $ '"$FUNCNAME"'

    - Git use cases
    $ '"$FUNCNAME"' -t git "Undo the most recent local commits"
    $ '"$FUNCNAME"' -t git "Clean up local branches"
    $ '"$FUNCNAME"' -t git "Setup LFS for images"

    - Working with the GitHub CLI in the terminal
    $ '"$FUNCNAME"' -t gh "Create pull request"
    $ '"$FUNCNAME"' -t gh "List pull requests waiting for my review"
    $ '"$FUNCNAME"' -t gh "Summarize work I have done in issues and pull requests for promotion"

    - General use cases
    $ '"$FUNCNAME"' "Kill processes holding onto deleted files"
    $ '"$FUNCNAME"' "Test whether there are SSL/TLS issues with github.com"
    $ '"$FUNCNAME"' "Convert SVG to PNG and resize"
    $ '"$FUNCNAME"' "Convert MOV to animated PNG"'

    test -z "$argv"; and echo $__USAGE && return 1;

    # Parse arguments using argparse
    argparse 'd/debug' 'h/help' 'hostname=' 't/target=' -- $argv

    # Handle help flag
    if set -q _flag_help
        echo "$__USAGE"
        return 0
    end

    # Handle debug flag
    if set -q _flag_debug
        set -g GH_DEBUG "api"
    end

    # Handle hostname flag
    if set -q _flag_hostname
        set -g GH_HOST "$_flag_hostname"
    end

    # Handle target flag
    if set -q _flag_target
        set -g TARGET "$_flag_target"
    end

    # Create temporary file
    set tmpfile (mktemp -t gh-copilotXXXXXX)

    # Clean up temporary file on exit
    function clean_tmpfile --on-event fish_exit
        rm -f "$tmpfile"
    end

    # Run the gh copilot suggest command
    if env GH_DEBUG="$GH_DEBUG" GH_HOST="$GH_HOST" gh copilot suggest -t "$TARGET" $argv --shell-out "$tmpfile"
        if test -s "$tmpfile"
            set fixed_cmd (cat "$tmpfile")

            # Update the history with the fixed command
            history -s (history 1 | cut -d' ' -f4-)
            history -s "$fixed_cmd"

            # Print a newline for clarity
            echo

            # Execute the fixed command
            eval "$fixed_cmd"
        end
    else
        return 1
    end
end
