require'floatqfix'
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
