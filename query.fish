function query_tasks
    set -l tasks (ag -Q '- [ ]')
    for task in $tasks
        echo $task
    end
end

function query_tag
    if test -z "$argv"
        echo ''
    else
        if test (count $argv) -gt 1
            set -l tasks $argv[1]
            set -l tag '\\'$argv[2]
            for task in $tasks
                echo $task | rg "\\$tag
            end
            
        else
        end
    end

end
