function fzf()
    local source = 'fd . --type f'
    local sink = function(selected)
        if selected and #selected > 0 then
            qrun_lua(selected)
        end
    end
    local options = '--prompt="Select a file> "'

    fzf_run({source = source, sink = sink, options = options})
end
