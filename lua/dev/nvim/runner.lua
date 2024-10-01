-- run commands on tmux/zellij panes
-- Usage: :Run <command> -- float
-- Usage: :Run tab <command> -- new tab

local M = {}
-- include directions for new panes
function M.run_command(opts)
    local z_opts = {cmd = '', args = '', win_type = 'pane', dir = 'left'}


                -- z_opts.args = ' --floating'
    -- the arguments before a '--' are options for the command
    -- if no '--' is present, the command is assumed to be a pane command
    local res = opts.args:match('%-%-')
    if res ~= nil then
        print('matched: fargs: ', vim.inspect(opts.fargs))
        for i, opt in ipairs(opts.fargs) do
            if opt == '--' then
                z_opts.cmd =  table.concat(opts.fargs, ' ', i+1)
                break
            end
            if opt == 'float' then
                z_opts.args = z_opts.args .. ' --floating'
            elseif opt == 'close-on-exit' then
                z_opts.args = z_opts.args .. ' --close-on-exit'
            elseif  opt == 'right' or opt == 'left' or opt == 'up' or opt == 'down' then
                z_opts.args = z_opts.args .. ' --direction ' .. opt
            elseif opt == 'in-place' then
                z_opts.args = z_opts.args .. ' --' .. opt
            elseif opt == 'start-suspended' then
                z_opts.args = z_opts.args .. ' --start-suspended'
            else
                print('Invalid option: ' .. opt)
            end
        end
    else
        print('it did not match: ' .. opts.args)
        z_opts.cmd = opts.args
    end
    local cmd = 'zellij run ' .. z_opts.args .. ' -- ' .. z_opts.cmd
    -- if #z_opts.args > 0 then
        -- cmd = cmd .. ' -- '  .. z_opts.cmd
    -- else
    --     cmd = cmd .. ' ' .. z_opts.cmd
    -- end

    print('cmd: ', cmd)
    local err, msg = pcall(os.execute, opts.cmd )
    if err then
        print('Error running command: ' .. msg)
    else
        print('Command ran successfully with: ', msg)
    end
end

-- create the command
vim.api.nvim_create_user_command("Run", function(opts) M.run_command(opts) end, {nargs = "+", bang = true, desc = 'run a command iwith zellij in the current pane or a new pane (float or aside)'})

vim.api.nvim_create_user_command(
    'MyCommand',           -- Command name
    function(opts)         -- Function to execute
        -- Handle arguments here
        print('Arguments received:')
        for i, arg in ipairs(opts.fargs) do
            print(string.format('Argument %d: %s', i, arg))
        end
    end,
    { nargs = '+' }        -- '+' means one or more arguments required
)

return M
