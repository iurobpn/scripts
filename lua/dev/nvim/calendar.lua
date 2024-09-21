local api = vim.api
local M = {}
local month_names = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
}

-- Get the first day of the month and how many days in the month
function M.get_month_data(year, month)
    -- Lua's os.date uses 1-indexed months
    local first_day = tonumber(os.date("%w", os.time{year=year, month=month, day=1}))
    local days_in_month = tonumber(os.date("%d", os.time{year=year, month=month + 1, day=0}))
    return first_day, days_in_month
end

-- Draw the calendar dynamically based on the window size
function M.draw_calendar(year, month)
    -- Get window dimensions
    local win_width = api.nvim_win_get_width(0)-2
    local win_height = api.nvim_win_get_height(0)-1

    -- Calculate the number of squares and padding
    local horizontal_padding = 10
    local vertical_padding = 3
    local total_width = win_width - 2 * horizontal_padding
    local total_height = win_height - 2 * vertical_padding
    local square_width = math.floor((total_width - 8) / 7)
    local square_height = math.floor(total_height / 5)

    print("Win width: " .. win_width)
    print("Win height: " .. win_height)
    print("Square width: " .. square_width)
    print("Square height: " .. square_height)


    -- Create a new buffer or use the current one
    -- local buf = api.nvim_get_current_buf()

    -- Create a new buffer or use the current one
    local buf = api.nvim_create_buf(false, true)  -- regular buffer, listed
    api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    -- Clear the buffer before redrawing
    -- api.nvim_buf_set_lines(buf, 0, -1, false, {})


    -- Set Gruvbox colors
    api.nvim_command('hi CalendarSquare guibg=#3c3836')   -- Dark grey for squares
    api.nvim_command('hi CalendarBorder guifg=#504945')   -- Lighter grey for borders
    api.nvim_command('hi CalendarBackground guibg=#282828') -- Darkest black for background

    local hpadding_str = string.rep(" ", horizontal_padding)
    local horiz_line = hpadding_str .. string.rep("_", square_width * 7 + 8) .. hpadding_str
    local blanc_line = string.rep(" ", win_width)
    -- Add padding to the top
    for i = 1, vertical_padding do
        api.nvim_buf_set_lines(buf, -1, -1, false, { blank_line })
    end

    -- Get month data
    local first_day, days_in_month = M.get_month_data(year, month)

    -- Add month title centered
    local month_title = string.format(" %s %d ", month_names[month], year)
    local title_padding = math.floor((win_width - #month_title) / 2)
    api.nvim_buf_set_lines(buf, -1, -1, false, { string.rep(" ", title_padding) .. month_title })

    -- Add day labels (Su Mo Tu We Th Fr Sa)
    local day_labels = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"}
    local days_padding = math.floor((square_width - 3)/2)
    print('days_padding: ' .. days_padding)

    local day_labels = '|' .. string.rep(" ", days_padding) .. table.concat(day_labels, string.rep(" ", days_padding) .. '|' .. string.rep(' ', days_padding)) .. string.rep(" ", days_padding) .. '|' 
    print('day_labels size: ' .. #day_labels)
    api.nvim_buf_set_lines(buf, -1, -1, false, { string.rep(" ", horizontal_padding) .. day_labels })

    -- Add the days with the calculated padding and sizes
    local day = 1
    for week = 1, 6 do
        local week_str = string.rep(" ", horizontal_padding)
        for day_of_week = 1, 7 do
            if (week == 1 and day_of_week <= first_day) or (day > days_in_month) then
                week_str = week_str .. string.rep(" ", square_width)
            else
                week_str = week_str .. "|"
                if day < 10 then
                    week_str = week_str .. string.rep(" ", math.floor((square_width - 3) / 2)) .. string.format(" %d ", day) .. string.rep(" ", math.ceil((square_width - 3) / 2))
                else
                    week_str = week_str .. string.rep(" ", math.floor((square_width - 4) / 2)) .. string.format(" %d ", day) .. string.rep(" ", math.ceil((square_width - 4) / 2))
                end
                -- week_str = week_str .. "|"
                day = day + 1
            end
        end
        week_str = week_str .. "|" .. string.rep(" ", horizontal_padding)
        local week_square = {horiz_line, blanc_line, week_str, blanc_line}
        api.nvim_buf_set_lines(buf, -1, -1, false, week_square)
        api.nvim_buf_add_highlight(buf, -1, 'CalendarSquare', week + 1, 0, -1)
    end

    -- Add padding to the bottom
    for i = 1, vertical_padding do
        api.nvim_buf_set_lines(buf, -1, -1, false, { string.rep(" ", win_width) })
    end
    api.nvim_win_set_buf(0, buf)

    -- Set the buffer to be unmodifiable
    api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.cmd('set nonumber')
    vim.cmd('set norelativenumber')
end

-- Function to navigate months
local current_year = 2024
local current_month = 9

function M.change_month(direction)
    current_month = current_month + direction
    if current_month < 1 then
        current_month = 12
        current_year = current_year - 1
    elseif current_month > 12 then
        current_month = 1
        current_year = current_year + 1
    end
    M.draw_calendar(current_year, current_month)
end

-- Key mappings for navigating months
api.nvim_set_keymap('n', 'h', ':lua M.change_month(-1)<CR>', { noremap = true, silent = true })
api.nvim_set_keymap('n', 'l', ':lua M.change_month(1)<CR>', { noremap = true, silent = true })

-- Auto resize the calendar when window size changes
api.nvim_command('autocmd VimResized * lua M.draw_calendar(current_year, current_month)')

-- Initial draw
M.draw_calendar(current_year, current_month)
