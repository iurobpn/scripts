local M = {}

function M.run(arg)
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
    if arg.source_append then
        source = source .. ' ' .. arg.source_append
    end

    if not sink then
        sink = function(selected)
            vim.cmd('edit ' .. selected)
        end
    end
    if not options then
        options = '--prompt="Select a file> "'
    end

    vim.fn['fzf#run']({source = source, sink = sink, options = options})
end
return M
