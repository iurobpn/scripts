function query_tasks
    set -l tasks (ag '\- \[ \]')
    for task in $tasks
        echo $task
    end
end

function query_tag
    if test -z "$argv"
        echo 'Usage: query_tag <tasks> <tag>'
        return
    end
    set tag $argv[1]
    set tasks (cat)
    for task in $tasks
        echo $task | rg '#today'
    end

    # for task in $tasks
    #     echo $task | ag '$tag'
    # end

    echo (count $tasks)
    echo $tag
end

function query_and
    if test -z "$argv"
        echo 'Usage: query_union <tasks> <tag1> <tag2>'
        return
    end
    set -l tag1 '\\'$argv[1]
    set -l tag2 '\\'$argv[2]
    while read -l task
        set tasks $tasks $task
    end
    echo $tasks | rg "\\$tag1" | rg "\\$tag2"
end

function query_or
    if test -z "$argv"
        echo 'Usage: query_union <tasks> <tag1> <tag2>'
        return
    end
    set -l tag1 '\\'$argv[1]
    set -l tag2 '\\'$argv[2]
    set -l tasks (cat)
    for task in $tasks
        if echo $task | rg "\\$tag1"
            echo $task
        else
            echo $task | rg "\\$tag2"
        end
    end
end

function process_input
    # Capture all input from stdin at once
    set input (cat)

    # Print the input once all is captured
    echo "Received input:"
    echo $input
end

function process_input2
    set input

    # Read lines from stdin until EOF or pipe closes
    while read -l line
        set -a input $line
    end

    # Process the input after reading
    echo $input
end
