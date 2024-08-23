function OpenQuickfixInFloat()
    local lines = vim.fn.getqflist({size = 1}).size
    if lines == 0 then
        print("Quickfix list is empty.")
        return
    end

    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.3)
    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = 'minimal',
        border = 'rounded'
    }

    vim.cmd('copen')
    local winid = vim.fn.win_getid()
    vim.api.nvim_win_set_config(winid, opts)
    vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':lua CloseFloatQuickfix()<CR>', { noremap = true, silent = true })
end
-- Function to close the floating quickfix window
function CloseFloatQuickfix()
    vim.api.nvim_win_close(0, true)
end
local log_file = '/tmp/error_lua.log'
function GetLuaQuickfix(filename)
    local fmt = string.format
    os.execute(fmt('lua.fish %s', filename))
    vim.cmd(fmt('cfile %s', log_file))
    OpenQuickfixInFloat(log_file)
end



function GetLuaQuickfixFzf()
  vim.fn['fzf#run']({
    source = 'find . -type f', -- or any other file search command
    sink = function(selected)
      if selected and #selected > 0 then
        GetLuaQuickfix(selected)
      end
    end,
    options = '--prompt="Select a file> "'
  })
end

vim.api.nvim_set_keymap('n', '<F3>', ':lua GetLuaQuickfixFzf()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F4>', ':lua GetLuaQuickfix(', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>q', ':lua OpenQuickfixInFloat()<CR>', { noremap = true, silent = true })
