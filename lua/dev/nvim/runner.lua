-- run commands on tmux/zellij panes
-- Usage: :Run <command> -- float
-- Usage: :Run tab <command> -- new tab

local M = {}
-- include directions for new panes
function M.run_command(...)
    local opts = {...}
    local is_nil = opts[1] == nil
    opts = opts[1] or {}
    if type(opts) == 'string' or is_nil then
        opts = {cmd = opts, win_type = 'pane', dir = 'left'}
    end
    if opts.win_type == 'float' then
        vim.cmd("!zellij run -c -f -- " .. opts.cmd)
    elseif is_nil or opts.win_type == 'pane' then
        vim.cmd("!zellij run -c -d " .. opts.dir .. ' -- ' .. opts.cmd)
    else
        vim.cmd("!zellij run -c -d left -- " .. opts.cmd)
    end
end

-- create the command
vim.api.nvim_create_user_command("Run", "lua require'dev.nvim.runner'.run_command(<args>)", {
    nargs = "+",
})

return M
