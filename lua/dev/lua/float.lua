require('class')
local Log = require('dev.lua.log')
local fmt = string.format
local log = Log('float')

Window = {
    relative = 'editor',
    row = 0, -- relative values
    col = 0,
    relative_sizes = true,
    width = 0,
    height = 0,
    style = 'minimal',
    border = 'rounded',
    modifiable = true,

    content = '',
    filename = '',
    -- focusable = true,
    -- zindex = 50,
    -- external = false,
    -- title = "draft",

    maps = {
        n = {
            {
                keys = 'q',
                cmd = ':lua Window.close()<CR>',
                opts = { noremap = true, silent = true }
            },
        },
        i = {},
        v = {},
    },
    current = false,
    floats = {}
}



function Window:ui_cols()
    return vim.api.nvim_get_option("columns")
end
function Window:ui_rows()
    return vim.api.nvim_get_option("lines")
end

function Window.popup(...)
    local win = Window()
    local args = {...}
    args = args[1]
    -- local args = {...}
    print('popup args', require'inspect'.inspect(args))
    if args then
        for k, v in pairs(args) do
            print(k, v)
            win[k] = v
        end
    end
    win.relative_sizes = false
    win.width = 6
    win.height = 1
    win.border = "single"
    win.zindex = 50
    win.row = 0
    win.col = 0
    win.anchor = 'NW'
    win.style = "minimal"
    win.modifiable = false
    win.cursor = false
    win.current = false
    return win
end

function Window:set_absolute_sizes()
    if self.width == 0 then
        self.width = math.floor(self:ui_cols()/2)
    end
    if self.height == 0 then
        self.height = math.floor(self:ui_rows()/2)
    end
    if self.row == 0 then
        self.row = math.floor((self:ui_rows() - self.height) / 2)
    end
    if self.col == 0 then
        self.col = math.floor((self:ui_cols() - self.width) / 2)
    end
    return self.width, self.height, self.col, self.row
end

function Window:set_relative_sizes()
    local ui_width = self:ui_cols()
    local ui_height = self:ui_rows()
    local width, height = 0, 0
    if self.width == 0 then
        width = ui_width*0.5
    else
        width = ui_width*self.width
    end
    if self.height == 0 then
        height = ui_height*0.5
    else
        height = ui_height*self.height
    end
    local row, col = 0, 0
    if self.row == 0 then
        row = (ui_height - height) * 0.5
    else
        row = (ui_height - height) * self.row
    end
    if self.col == 0 then
        col = (ui_width - width) * 0.5
    else
        col = (ui_width - width) * self.col
    end
    return math.floor(width), math.floor(height), math.floor(col), math.floor(row)
end
function Window:set_sizes()
    local width, height, col, row = 0, 0, 0, 0
    if self.relative_sizes then
        width, height, col, row = self:set_relative_sizes()
    else
        width, height, col, row = self:set_absolute_sizes()
    end
    return width, height, col, row
end
function Window:params()
    local width, height, col, row = self:set_sizes()
    print(fmt('width: %s, height: %s, col: %s, row: %s', width, height, col, row))
end

function Window.up()
    -- get the current window  win id
    Window.move(0, 3)
end
function Window.down()
    -- get the current window  win id
    Window.move(0, -3)
end
function Window.left()
    -- get the current window  win id
    Window.move(5, 0)
end
function Window.right()
    -- get the current window  win id
    Window.move(-5, 0)
end
function Window.move(dx, dy)
    -- get the current window  win id
    local win_id = vim.fn.win_getid()


    if not win_id or not vim.api.nvim_win_is_valid(win_id) then
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.row[false] = win_config.row[false] - dy  -- Adjust the row positiondx, dy
    win_config.col[false] = win_config.col[false] - dx  -- Adjust the row positiondx, dy
    vim.api.nvim_win_set_config(win_id, win_config)
end
function Window.close()
    local win_id = vim.fn.win_getid()
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        --remove mapping
        vim.api.nvim_buf_del_keymap(0, 'n', 'q')
        vim.api.nvim_win_close(win_id, true)
    else
        print("No floating window to close.")
    end
    Window.floats[win_id] = nil -- morre disgrama!!!
end
function Window:open()
    local width, height, col, row = self:set_sizes()

    local opts = {
        relative = self.relative,
        row = row,
        col = col,
        width = width,
        height = height,
        title = self.title,
        style = self.style,
        border = self.border,
        focusable = self.focusable,
        zindex = self.zindex,
        external = self.external,
        anchor = self.anchor,
    }


    if not self.cursor then
    --     vim.opt.guicursor = vim.o.background
        vim.cmd(fmt('highlight Cursor guifg=%s guibg=%s', vim.o.background, vim.o.background))
    end



    -- vim.cmd([[highlight Cursor guifg=bg guibg=bg]])

    if self.current then
        self.id, self.buf, self.filename = Window.get_current()
    elseif self.id then
        self.buf, self.filename = Window.get_window(self.id)
    elseif self.filename ~= nil and #self.filename > 0 then
        self:load(self.filename)
    elseif self.content ~= nil and #self.content > 0 then
        self.buf = vim.api.nvim_create_buf(false, true)
        self:write(self.content, 0, false)
    else
        self.buf = vim.api.nvim_create_buf(false, true)
    end



    vim.api.nvim_buf_set_option(self.buf, 'modifiable', self.modifiable)
    self.id = vim.api.nvim_open_win(self.buf, true, opts)



    -- vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':lua close_float()<CR>', { noremap = true, silent = true })
    -- vim.api.nvim_buf_set_keymap(buf, 'n', '', map.cmd, map.opts)
    for mode, maps in pairs(self.maps) do
        for _, map in pairs(maps) do
            if map ~= nil then
                vim.api.nvim_buf_set_keymap(self.buf, mode, map.keys, map.cmd, map.opts)
            end
        end
    end
    Window.floats[self.id] = self
end

function Window:load(filename)
    self.buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(self.buf, self.filename)
    vim.api.nvim_command("edit " .. self.filename)
end

function Window.get_window(id)
    -- Get the current window and buffer
    local buf = vim.api.nvim_win_get_buf(id)
    local filename = vim.api.nvim_buf_get_name(buf)

    return buf, filename
end

function Window.get_current()
    -- Get the current window and buffer
    local id = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(buf)

    return id, buf, filename
end

    -- no link to the file, like in :r filename
function Window:read(filename)
    vim.api.nvim_buf_call(self.buf, function()
        vim.api.nvim_command("edit " .. filename)
    end)
end

function Window.is_floating(id)
    return  vim.api.nvim_win_get_config(id).relative ~= ''
end

function Window:write(content, line_nr, append)
    if append == nil then
        append = false
    end
    if type(content) == 'string' then
        content = vim.split(content, '\n')
        if type(content) == 'string' then
            content = {content}
        end
    end
    print('content', require'inspect'.inspect(content))
    vim.api.nvim_buf_set_lines(self.buf, line_nr, -1, append, content) -- overwrite file
end

function test_window()
    local win = Window()
    win.width = 0.5
    win.height = 0.5
    win.row = 0.5
    win.col = 0.5
    win:open()
    win:params()
end

function test_popup()
    local win = Window.popup({content='hello'})
    print('popup ', require'inspect'.inspect(win))
    win:open()
    win:params()
end

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
    local opts = get_options({rel_width = 0.6, rel_height = 0.6})

    if arg then
        for k, v in pairs(arg) do
            opts[k] = v
        end
    end

    -- Open the quickfix window
    local win_id = vim.fn.win_getid()
    -- Convert the quickfix window into a floating window
    if not opts.buf then
        opts.buf = vim.api.nvim_create_buf(false, true)  -- false for listed, true for scratch
    end
    local buf = opts.buf
    opts.buf = nil
    vim.api.nvim_open_win(buf, true, opts) -- true for enter the new window

    -- Map 'q' to close the floating quickfix window
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':lua close_float()<CR>', { noremap = true, silent = true })
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


function popup(str, ...)
    local buf = vim.api.nvim_create_buf(false, true)  -- false for listed, true for scratch

    ui_cols = vim.api.nvim_get_option("columns")
    ui_rows = vim.api.nvim_get_option("lines")
    local opts = {
        relative = 'editor',
        width = 8,
        height = 3,
        row = math.floor((ui_rows - rows) / 2),
        col = math.floor((ui_cols - cols) / 2),
        style = 'minimal',
        border = 'rounded',
        modifiable = false,
    }
    for k, v in pairs(arg) do
        opts[k] = v
    end

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

function layout_popup()
    local Popup = require("nui.popup")
    local Layout = require("nui.layout")

    local popup_one, popup_two = Popup({
        enter = true,
        border = "single",
    }), Popup({
        border = "double",
    })

    local layout = Layout(
        {
            position = "50%",
            size = {
                width = 80,
                height = "60%",
            },
        },
        Layout.Box({
            Layout.Box(popup_one, { size = "40%" }),
            Layout.Box(popup_two, { size = "60%" }),
        }, { dir = "row" })
    )

    local current_dir = "row"

    popup_one:map("n", "r", function()
        if current_dir == "col" then
            layout:update(Layout.Box({
                Layout.Box(popup_one, { size = "40%" }),
                Layout.Box(popup_two, { size = "60%" }),
            }, { dir = "row" }))

            current_dir = "row"
        else
            layout:update(Layout.Box({
                Layout.Box(popup_two, { size = "60%" }),
                Layout.Box(popup_one, { size = "40%" }),
            }, { dir = "col" }))

            current_dir = "col"
        end
    end, {})

    layout:mount()
end

Window = class(
    Window,
    function(self, ...)
        local opts = arg or {}
        for k, v in pairs(opts) do
            self[k] = v
        end
        return self
    end
)
-- create mappings for the move functions
vim.api.nvim_set_keymap('n', '<C-S-Up>', ':lua Window.up()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-Down>', ':lua Window.down()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-Left>', ':lua Window.left()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-Right>', ':lua Window.right()<CR>', { noremap = true, silent = true })



-- handle_link()
-- ag  '\- \[.\]' | cut -d : -f1,2 | sed 's/:/ /g'                                                                                                                   22.3.0 󰌠 3.12.4 (python3.12)

--setup the buffer with links and test
-- setup_buffer_with_links()
return Window
