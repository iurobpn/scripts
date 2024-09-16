local Window = require('dev.nvim.ui.float').Window
local views = {}

function views.new(pos, size)
    local win = Window()
    if pos ~= nil and size ~= nil then
        win:config({position = pos, size = size})
    end
    win:open()
    return win
end

function views.messages()
    local win = views.minimal()
    -- get the messages from nvim
    local messages = vim.api.nvim_exec('messages', true)
    win:config(
        {
            content = messages,
            modifiable = false,
            buffer = {
                scratch = true,
                listed = false,
            }
        })
    win:open()
    return win
end

function views.fit()
    -- Get the lines of the buffer
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Calculate the height (number of lines)
    local height = #lines

    -- Calculate the width (the length of the longest line)
    local width = 0
    for _, line in ipairs(lines) do
        if #line > width then
            width = #line
        end
    end

    local win = Window.minimal()
    win:config({
        size = {
            absolute = {
                width = width,
                height = height,
            },
            buffer = views.get_scratch_opt(),
        },
        modifiable = false,
        current = false,
    })

end

function views.get_scratch_opt()
    return {
        scratch = true,
        listed = false,
    }
end

function views.minimal()
    local win = Window()
    win:config({style = "minimal"})
    return win
end

function views.open_current_window()
    local win = Window()
    win.current = true
    win:open()
end

function views.popup(...)
    local win = Window()

    local args = {...}
    args = args[1]
    -- local args = {...}
    local opts = {
        size = {
            absolute = {
                width = 8,
                height = 1,
            }
        },
        border = "round",
        zindex = 50,
        position = 'center',
        anchor = 'NW',
        style = "minimal",
        modifiable = false,
        cursor = false,
        current = false,
    }
    if args then
        for k, v in pairs(args) do
            opts[k] = v
        end
    end
    win.config(opts)

    return win
end

function views.open(content)
    local win = Window()
    win:config({content = content})
    win:open()
    return win
end

vim.api.nvim_create_user_command("WinNew",         'lua dev.nvim.ui.views.new()',          {})
vim.api.nvim_create_user_command("WinOpenCurrent", 'lua dev.nvim.ui.views.open_current()', {})
vim.api.nvim_create_user_command("WinMessages",    'lua dev.nvim.ui.views.messages()',     {})

vim.api.nvim_set_keymap('n', '<LocalLeader>n', ':WinNew<CR>',         { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'gç',             ':WinOpenCurrent<CR>', { noremap = true, silent = true })

return views
