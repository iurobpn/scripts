
-- simplifies creation of options for windows, not finished and not tested
function get_options(...)
    local opts = arg

    local ui_cols = vim.api.nvim_get_option("columns")
    local ui_rows = vim.api.nvim_get_option("lines")

    local cols = math.floor(ui_cols * 0.5)
    local rows = math.floor(ui_rows * 0.5)

    if opts ~= nil and opts.rel_width ~= nil then
        cols = math.floor(ui_cols * opts.rel_width)
        opts.rel_width = nil
    end

    if opts ~= nil and opts.rel_height ~= nil then
        cols = math.floor(ui_cols * opts.rel_height)
        opts.rel_height = nil
    end

    if opts ~= nil and opts._rel_row ~= nil then
       opts.row = math.floor((ui_cols - rows) * opts.rel_row)
        opts.rel_row = nil
    end

    if opts ~= nil and opts.rel_col ~= nil then
       opts.col = math.floor((ui_rows - cols) * opts.rel_col)
        opts.rel_col = nil
    end

    local out = {
        relative = 'editor',
        width = ui_cols,
        height = ui_rows,
        row = math.floor((ui_rows - rows) / 2),
        col = math.floor((ui_cols - cols) / 2),
        style = 'minimal',
        border = 'rounded',
    }

    for k, v in pairs(opts) do
        out[k] = v
    end

    return out
end
function open_float(...)
    -- Calculate window size and position
    local opts = nil
    if arg ~= nil then
        opts = arg
    end
    if not opts  then
        opts = get_options({rel_width = 0.6, rel_height = 0.6})
    end
    if not opts.buf then
        opts.buf = 0
    end

    -- Open the quickfix window
    local win_id = vim.fn.win_getid()
    -- Convert the quickfix window into a floating window
    vim.api.nvim_open_win(opts.buf, true, opts) -- true for enter the new window

    -- Map 'q' to close the floating quickfix window
    vim.api.nvim_buf_set_keymap(opts.buf, 'n', 'q', ':lua close_float()<CR>', { noremap = true, silent = true })
    -- Set an autocmd to unmap the key when the floating window is closed
    -- local buf = vim.api.nvim_get_current_buf() 
    -- vim.api.nvim_create_autocmd('WinClosed', {
    --     callback = function(args)
    --         if tonumber(args.match) == win then
    --             local buf = vim.api.nvim_get_current_buf() 
    --             vim.api.nvim_buf_del_keymap(buf, 'n', 'q')
    --         end
    --     end,
    --     once = true,
    -- })

end


function popup(str,width,height)
    local buf = vim.api.nvim_create_buf(false, true)  -- false for listed, true for scratch

    ui_cols = vim.api.nvim_get_option("columns")
    ui_rows = vim.api.nvim_get_option("lines")
    local opts = {
        relative = 'editor',
        width = width or 8,
        height = height or 3,
        row = math.floor((ui_rows - rows) / 2),
        col = math.floor((ui_cols - cols) / 2),
        style = 'minimal',
        border = 'rounded',
    }

    local win = vim.api.nvim_open_win(buf, true, opts)
end

function create_float(filename)
    -- Create a new buffer
    local buf = vim.api.nvim_create_buf(false, true)  -- false for listed, true for scratch


    qfloat.win_id = vim.fn.win_getid()
    -- Define window options
    local opts = get_options()

    -- Open the floating window
    local win = vim.api.nvim_open_win(buf, true, opts)


    -- Set the buffer name and content
    if filename then
        vim.api.nvim_buf_set_name(buf, filename)
        vim.api.nvim_command("edit " .. filename)
    end

    -- replaces the in lines in the buffers
    -- vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

    vim.api.nvim_win_close(win, true)  -- true indicates force close

end
-- generate links in file:number
-- Create a buffer with example links
local function setup_buffer_with_links()
    -- Create a new buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Example list of files with line numbers
    local lines = {
        "example.lua:10",
        "another_file.lua:20",
        "yet_another.lua:30"
    }

    -- Set the buffer lines
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Define a pattern to match 'filename.lua:number'
    local pattern = [[\v(\S+\.lua):(\d+)]]

    -- Highlight the matching pattern
    vim.fn.matchadd("Underlined", pattern)

    -- Set the buffer as the current buffer
    vim.api.nvim_set_current_buf(buf)

    -- Set an autocmd to handle opening files when the link is selected
    vim.api.nvim_exec([[
    augroup FileLinkHandler
      autocmd!
      autocmd CursorMoved <buffer> lua handle_link()
    augroup END
  ]], false)

    return buf
end


-- Open the buffer with links
local function open_file_as_float(filename, line)
    -- Create a new buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set the buffer name to the filename
    vim.api.nvim_buf_set_name(buf, filename)

    -- Load the file content into the buffer
    vim.api.nvim_command("edit " .. filename)

    -- Get the current UI size
    opts = get_options({rel_width = 0.8, rel_height = 0.8})

    -- Open the floating window
    local win = vim.api.nvim_open_win(buf, true, opts)

    -- Move to the specific line
    vim.api.nvim_win_set_cursor(win, {line, 0})
end

function open_current_window_as_float(...)
    local opts = arg or get_options()
    -- Get the current window and buffer
    local current_win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_get_current_buf()

    -- Get the size of the current window (optional, for resizing purposes)
    local width = vim.api.nvim_win_get_width(current_win)
    local height = vim.api.nvim_win_get_height(current_win)

    -- Close the current window
    -- vim.api.nvim_win_close(current_win, false)

    -- Create a floating window with the same buffer
    vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':lua qclose()<CR>', { noremap = true, silent = true })
    vim.api.nvim_open_win(current_buf, true, opts)
end
-- open_file_float("example.lua", 10)
function close_float(winid)
    local buf = 0
    if not winid then
        winid = vim.fn.win_getid()
        buf = vim.api.nvim_win_get_buf(winid)
    else
        buf = vim.api.nvim_win_get_buf(winid)
    end
    if winid and vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_buf_del_keymap(buf, 'n', 'q')
        vim.api.nvim_win_close(winid, true)
    else
        print("No floating window to close.")
    end
end

function convert_current_window_to_float()
    -- Get the current window and buffer
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()

    -- Set the current window to be a floating window
    local opts = get_options({rel_width = 0.5, rel_height = 0.5, rel_row = 0.5, rel_col = 0.5})
    vim.api.nvim_win_set_config(win, opts)

    -- Ensure the window is focused for editing
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':lua qclose()<CR>', { noremap = true, silent = true })
end

local function handle_link()
    -- Get the current line content
    local line = vim.api.nvim_get_current_line()

    -- Match the pattern 'filename.lua:number'
    local pattern = "([^:]+):(%d+)"
    local filename, line_number = string.match(line, pattern)

    if filename and line_number then
        -- Make the link clickable
        vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', '', {
            noremap = true,
            silent = true,
            callback = function()
                open_in_floating_window(filename, tonumber(line_number))
            end
        })
    end
end
-- handle_link()
-- ag  '\- \[.\]' | cut -d : -f1,2 | sed 's/:/ /g'                                                                                                                   22.3.0 󰌠 3.12.4 (python3.12)

--setup the buffer with links and test
setup_buffer_with_links()
