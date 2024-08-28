require('dev.nvim.ui.float')
Clock = {
    window = nil
}
-- Clock = class(Clock)

function Clock.update(buf, t_period)
    if not t_period then
        t_period = 1000 -- ms
    end
    -- Function to update the time in the buffer
    local function update_time()
        -- Get the current time
        local current_time = os.date("%H:%M:%S")
        -- Update the buffer content
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {current_time})
    end

    -- Run the update_time function every 60 seconds
    vim.defer_fn(function()
        -- Check if the window still exists
        if vim.api.nvim_buf_is_valid(buf) then
            update_time()
            -- Re-run the function to continue the update loop
            Clock.update(buf, t_period)
        end
    end, t_period) -- 60000 ms = 1 min
end

function Clock.toggle()
    if Clock.window then
        Clock.close()
    else
        Clock.open()
    end
end
function Clock.open(t)
    local win = nil
    if Clock.window then
        win = Clock.window
    else
        print('Creating new clock')
        win = Window.popup()
    end
    t = t or 1000
    win:config(
        {
            name = 'clock',
            focusable = false,
            modifiable = true,
            size = {
                absolute = {
                    height = 1,
                    width = 8
                }
            },
            border = 'rounded',
            position = 'top-right'
        }
    )
    win:open()
    vim.cmd('wincmd p') -- clock is not focusable, so we need to focus the previous window
    -- win:params()
    Clock.update(win.buf, t)
    Clock.window = win
end

function Clock.close()
    if Clock.window then
        Clock.window:close()
        Clock.window = nil
    else
        print('Clock is not open')
    end
end
vim.api.nvim_create_user_command("Clock", "lua Clock.toggle()", {})
vim.api.nvim_create_user_command("ClockOpen", "lua Clock.open()", {})
vim.api.nvim_create_user_command("ClockClose", "lua Clock.close()", {})
