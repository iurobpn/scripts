local M = {}
function M.fzf()
    local source = 'fd . --type f'
    local sink = function(selected)
        if selected and #selected > 0 then
            qrun_lua(selected)
        end
    end

    fzf_run({source = source, sink = sink, options = options})
end

function M.fzf_run(arg)
    local source, sink

    local options
    if arg ~=nil then
        source = arg.source
        sink = arg.sink
        options = arg.options
    end
    if not source then
        source = 'fd . --type f --hidden --follow --exclude .git --exclude .gtags'
    end

    if not sink then
        sink = function(selected)
            print(selected)
        end
    end
    if not options then
        options = '--prompt="Select a file> "'
    end

    vim.fn['fzf#run']({source = source, sink = sink, options = options})
end
return M
