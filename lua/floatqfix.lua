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
vim.api.nvim_set_keymap('n', '<Leader>q', ':lua OpenQuickfixInFloat()<CR>', { noremap = true, silent = true })
