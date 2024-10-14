local Window = require('dev.nvim.ui.float').Window
local views = {}

function views.new()
    local win = Window()
    return win
end

function views.messages()
    local win = views.minimal()
    -- get the messages from nvim

    local messages = vim.api.nvim_exec('messages', true)
    if type(messages) == 'string' then
        messages = vim.split(messages, '\n')
    end
    win:config(
        {
            content = messages,
            buffer = {
                scratch = true,
                listed = false,
            },
            options = {
                buffer = {
                    modifiable = false,

                }
            }
        })
    win:open()
    return win
end

views.fixed_id = nil
function views.close_fixed_right()
    -- Close the rightmost window with 'winfixwidth' set
    if vim.api.nvim_win_get_option(views.fixed_id, 'winfixwidth') then
        vim.api.nvim_win_close(views.fixed_id, true)
        vim.notify("Fixed right window closed.")
    else
        vim.notify("No fixed right window found.")
    end
    views.fixed_id = nil
end

function views.toggle_fixed_right()
    if views.fixed_id ~= nil then
        views.close_fixed_right()
    else
        views.open_fixed_right()
    end
end

-- Map the function to a command for easy access
function views.open_fixed_right(buf)

    if buf ~= nil then
        -- Open a vertical split with the buffer
        vim.cmd('vertical sbuffer ' .. buf)
    else
        -- Open a vertical split
        vim.cmd('vertical vsplit')
    end
    -- Move it to the far right
    vim.cmd('wincmd L')
    -- Fix its width
    vim.cmd('setlocal winfixwidth')
    -- Ensure splits open to the right
    vim.o.splitright = true
    -- Calculate 25% of the current screen width
    local total_width = vim.o.columns
    local new_width = math.floor(total_width * 0.25)
    -- Set the window width
    vim.cmd('vertical resize ' .. new_width)
    
    -- Save the window ID for later
    views.fixed_id = vim.api.nvim_get_current_win()
end
-- Map the function to a command or keybinding if desired
vim.api.nvim_create_user_command('FixedRight', views.toggle_fixed_right, {})

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
        option = {
            buffer = {
                modifiable = true,
            }
        },
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

function views.scratch(content, ...)
    local opts = {...}
    opts = opts[1] or {}
    local win = Window()
    opts.buffer = views.get_scratch_opt()
    opts.content = content
    opts.option = {
        buffer = {
            modifiable = true,
        }
    }

    win:config(opts)
    return win
end

vim.api.nvim_create_user_command("WinNew",         'lua dev.nvim.ui.views.new()',          {})
vim.api.nvim_create_user_command("WinOpenCurrent", 'lua dev.nvim.ui.views.open_current()', {})
vim.api.nvim_create_user_command("Messages",    'lua dev.nvim.ui.views.messages()',     {})

vim.api.nvim_set_keymap('n', '<LocalLeader>n', ':WinNew<CR>',         { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'gç',             ':WinOpenCurrent<CR>', { noremap = true, silent = true })

return views
