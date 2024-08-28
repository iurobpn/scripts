require('dev.nvim.ui.float')
Float = {
    window = nil,
    buf = nil,
}

function Float.toggle()
    if Float.window then
        Float.close()
    else
        Float.open()
    end
end
-- function Float.toggle()
--     -- local hidden_zindex = -100  -- A zindex value that ensures the Float is beneath everything
--     -- local visible_zindex = 50  -- The default visible zindex
--
--     local id = vim.api.nvim_get_current_win()
--     if Float.hidden == nil and id == Float.visible then
--         Float.hidden = id
--         Float.visible = nil
--     elseif Float.visible == nil and Float.hidden ~= nil then
--         id = Float.hidden
--         Float.hidden = nil
--         Float.visible = id
--     elseif Float.hidden == nil and Float.visible == nil then
--         Float.open()
--         return
--     else
--         print('Cannot toggle Float window, inconsistent state')
--     end
--
--
--     if id ~= nil and Window.is_floating(id) then
--         local win_config = vim.api.nvim_win_get_config(id)
--         if win_config.zindex > 0 then
--             -- Set zindex to a very low value to hide it
--             print('Hiding window')
--             win_config.zindex = Float.hidden_zindex
--         else
--             -- Restore zindex to the default visible value
--             print('Show window')
--             win_config.zindex = Float.zindex
--         end
--         vim.api.nvim_win_set_config(id, win_config)
--     else
--         print('Window is not a floating window')
--     end
-- end
function Float.open()
    local win = nil
    if Float.window then
        win = Float.window
    else
        win = Window()
    end
    if not win then
        print('Error creating window (nil ret)')
        return
    end
    win:config(
        {
            name = 'draft',

            close_map = {
                mode = 'n',
                key = 'ESC',
                cmd = ':lua Float.close()<CR>',
                opts = { noremap = true, silent = true }
            },
        }
    )
    if Float.buf then
        win.buf = Float.buf
    end
    win:open()
    Float.buf = win.buf
    -- win:params()
    Float.window = win
    local win_config = vim.api.nvim_win_get_config(win.id)
    Float.zindex = win_config.zindex
    Float.visible = win.id
end

function Float.close()
    if Float.window then
        print('Closing float')
        Float.window.close()
        Float.window = nil
    else
        print('Window is not open')
    end
end

wins = {}

function test_pos()
    local win = Window()
    table.insert(wins,win)
    win:config(
        {
            name = 'draft1 ',
            position = 'top-right'
        }
    )
    win.name = win.name .. win.position
    win:open()

    win = Window()
    table.insert(wins,win)

    win:config(
        {
            name = 'draft2 ',
            position = 'top-left'
        }
    )
    win.name = win.name .. win.position
    win:open()

    win = Window()
    table.insert(wins,win)

    win:config(

        {
            name = 'draft3 ',
            position = 'bottom-right'
        }
    )
    win.name = win.name .. win.position
    win:open()

    win = Window()
    table.insert(wins,win)
    win:config(
        {
            name = 'draft4 ',
            position = 'bottom-left'
        }
    )
    win.name = win.name .. win.position
    win:open()

    print('corner Float sizes')
    for _, win in ipairs(wins) do
        print('Win: ' .. win.name)
        win:params()
    end
end


function Float.custom_win(pos,size)
    local win = Window()
    win:config(
        {
            name = 'draft1 ',
            position = pos,
            size = size
        }
    )
    win:open()
    Float.window = win
end
function Float.clear()
    if Float.window then
        Float.window:close()
        Float.window = nil
    else
        print('Window is not open')
    end
    Float.buf = nil
end


function close_wins()
    for i,win in ipairs(wins) do
        win:close()
    end
end

vim.api.nvim_create_user_command("Float", "lua Float.toggle()", {})
vim.api.nvim_create_user_command("FloatOpen", "lua Float.open()", {})
vim.api.nvim_create_user_command("FloatClose", "lua Float.close()", {})

-- define maps
vim.api.nvim_set_keymap('n', '<C-ç>', ':Float<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'ç+c', ':FloatClear<CR>', { noremap = true, silent = true })
