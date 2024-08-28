require('utils')
require('class')
local Log = require('dev.lua.log')

local fmt = string.format

local log = Log('float')

Window = {
    relative = 'editor',
    size = {
        relative = {
            width = 0.5,
            height = 0.5,
        },
        -- absolute = {
        --     height = 0,
        --     height = 0,
        -- },
    },
    position = 'center',
        -- {
         --    relative = {
         --    row = 0.5,
         --    col = 0.5,
        -- },
        -- absolute = {
        --     row = 0,
        --     col = 0,
        -- },
    -- },
    style = 'minimal',
    border = 'rounded',
    close = false, -- close current window when it is being floated

    content = '',
    filename = '',
    focusable = true,
    modifiable = true,
    -- zindex = 50,
    -- external = false,
    title = '',
    maps = {
        n = {
                -- keys = 'q',
                -- cmd = ':lua Window.close()<CR>',
                -- opts = { noremap = true, silent = true }
        },
        i = {},
        v = {},
    },
    close_map = {
        mode = 'n',
        key = 'q',
        cmd = ':lua Window.close()<CR>',
        opts = { noremap = true, silent = true }
    },
    current = false,
    floats = {},
    buffer = {
        listed = true,
        scratch = false,
    },
}

function Window:ui_width()
    return vim.api.nvim_get_option("columns")
end

function Window:ui_height()
    return vim.api.nvim_get_option("lines")
end

function Window:config(...)
    local opts = {...}
    opts = opts[1]
    if opts then
        for k, v in pairs(opts) do
            self[k] = v
        end
    end
end

function Window.popup(...)
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


function Window:get_size()
    local ui_width = self:ui_width()
    local ui_height = self:ui_height()

    local width = 0
    local height = 0
    if self.size.relative then
        width = ui_width*self.size.relative.width
        height = ui_height*self.size.relative.height
    elseif self.size.absolute then
        width = self.size.absolute.width
        height = self.size.absolute.height
    else
        error('Size not set size')
    end

    -- print('get size')
    -- print(fmt('UI: width: %s, height: %s', ui_width, ui_height))
    -- print(fmt('width: %s, height: %s', self.width, self.height))

    return width, height
end

function Window:set_size()
    self.width, self.height = self:get_size()
    self.width = math.floor(self.width)
    self.height = math.floor(self.height)

    -- print('set size')
    -- print(fmt('UI: width: %s, height: %s', self:ui_width(), self:ui_height()))
    -- print(fmt('width: %s, height: %s', self.width, self.height))
end

function Window:add_map(mode, keys, cmd, opts)
    table.insert(self.maps[mode], {keys = keys, cmd = cmd, opts = opts})
end

function Window:params()
    local width, height = self:get_size()
    local col, row = self:get_position()
    print(fmt('params: width: %s, height: %s, col: %s, row: %s', width, height, col, row))
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
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        return
    end

    if not win_id or not vim.api.nvim_win_is_valid(win_id) then
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.row[false] = win_config.row[false] - dy  -- Adjust the row positiondx, dy
    win_config.col[false] = win_config.col[false] - dx  -- Adjust the row positiondx, dy
    vim.api.nvim_win_set_config(win_id, win_config)
end

function Window:close(id)
    local win_id = 0
    if self == nil and id == nil then 
        win_id = vim.fn.win_getid()
    elseif not id then
        win_id = self.id
    elseif id then
        win_id = id
        Window.set_win(win_id)
    end
    if win_id and Window.is_floating(win_id) then
        local buf = vim.api.nvim_get_current_buf()
        Buffer.unmap(buf)
        vim.api.nvim_win_close(win_id, false)
        Window.floats[win_id] = nil
    else
        print("Current window is either invalid (id) or is not a float to close.")
    end
end

function Window.set_win(id)
    if vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_set_current_win(win_id)
    else
        print("Invalid window ID")
    end
end

function Window:options()

    return {
        relative = self.relative,
        row = self.row,
        col = self.col,
        width = self.width,
        height = self.height,
        title = self.title,
        style = self.style,
        border = self.border,
        focusable = self.focusable,
        zindex = self.zindex,
        external = self.external,
        anchor = self.anchor,
    }
end

function Window.close_all()
    for id, win in pairs(Window.floats) do
        if win ~= nil and Window.is_floating(id) then
            win:close()
        end
    end
end

function Window:open()
    self:set_size()
    self:set_position()


    if not self.cursor then
    --     vim.opt.guicursor = vim.o.background
        vim.cmd(fmt('highlight Cursor guifg=%s guibg=%s', vim.o.background, vim.o.background))
    end

    local id = nil
    if self.current then
        self.id, self.buf, self.filename = Window.get_current()
        self.close = true
        id = self.id
    elseif self.buf then

    elseif self.id then
        self.buf, self.filename = Window.get_window(self.id)
    elseif self.filename ~= nil and #self.filename > 0 then
        self:load(self.filename)
    elseif self.content ~= nil and #self.content > 0 then
        self.buf = vim.api.nvim_create_buf(self.buffer.listed, self.buffer,scratch)
        self:write(self.content, 0, false)
    else
        self.buf = vim.api.nvim_create_buf(self.buffer.listed, self.buffer,scratch)
    end


    local opts = self:options()
    -- inspect(self, 'self (win open()): ')
    -- inspect(opts, 'opts (win open()): ')
    vim.api.nvim_buf_set_option(self.buf, 'modifiable', self.modifiable)
    -- local opts = self:options()
    self.id = vim.api.nvim_open_win(self.buf, true, opts)

    if id ~= nil and self.close then
        vim.api.nvim_win_close(id, false)
    end

    --
    -- vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':lua close_float()<CR>', { noremap = true, silent = true })
    -- vim.api.nvim_buf_set_keymap(buf, 'n', '', map.cmd, map.opts)
    if not self.midifiable ~= nil then
        vim.api.nvim_buf_set_keymap(self.buf, self.close_map.mode, self.close_map.key, self.close_map.cmd, { noremap = true, silent = true })
    else
        vim.api.nvim_buf_set_keymap(self.buf, 'n', '<ESC>', self.close_map.cmd, self.close_map.opts)
    end
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
    if not filename or #filename == 0 then
        filename = self.filename
        if not filename or #filename == 0 then
            error('No filename provided')
            return
        end
    end
    self.buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(self.buf, filename)
    vim.api.nvim_command("edit " .. filename)
end

function Window.get_window(id)
    -- Get the current window and buffer
    local buf, filename = nil, nil
    if Window.is_floating(id) then
        buf = vim.api.nvim_win_get_buf(id)
        filename = vim.api.nvim_buf_get_name(buf)
    else
        print('window is not a float')
    end

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
    return id and vim.api.nvim_win_is_valid(id) and vim.api.nvim_win_get_config(id).relative ~= ''
end

function Window:write(content, line_nr, append)
    if line_nr == nil then
        line_nr = 0
    end
    if append == nil then
        append = false
    end
    if type(content) == 'string' then
        content = vim.split(content, '\n')
        if type(content) == 'string' then
            content = {content}
        end
    end
    vim.api.nvim_buf_set_lines(self.buf, line_nr, -1, append, content) -- overwrite file
end

function Window.snap_down()
    local win_id = vim.fn.win_getid()
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        print("Current window is not floating to snap down.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.row = vim.api.nvim_get_option("columns") - win_config.height
    vim.api.nvim_win_set_config(win_id, win_config)
end
function Window.snap_up()
    local win_id = vim.fn.win_getid()
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        print("Current window is not floating to snap up.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.row = 0
    vim.api.nvim_win_set_config(win_id, win_config)
end
function Window.snap_right()
    local win_id = vim.fn.win_getid()
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        print("Current window is not floating to snap right.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.col = vim.api.nvim_get_option("columns") - win_config.width
    vim.api.nvim_win_set_config(win_id, win_config)
end

function Window.snap_left()
    local win_id = vim.fn.win_getid()
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        print("Current window is not floating to snap left.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.col = 0
    vim.api.nvim_win_set_config(win_id, win_config)
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
    win:open()
    win:params()
end

function popup(str, ...)
    local buf = vim.api.nvim_create_buf(false, true)  -- false for listed, true for scratch

    ui_width = vim.api.nvim_get_option("columns")
    ui_height = vim.api.nvim_get_option("lines")
    local opts = {
        relative = 'editor',
        width = 8,
        height = 3,
        row = math.floor((ui_height - rows) / 2),
        col = math.floor((ui_width - cols) / 2),
        style = 'minimal',
        border = 'rounded',
        modifiable = false,
    }
    for k, v in pairs(arg) do
        opts[k] = v
    end

    local win = vim.api.nvim_open_win(buf, true, opts)
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
    {
        constructor = function(self, ...)
            local opts = {...}
            opts = opts[1]
            if opts then
                for k, v in pairs(opts) do
                    if k ~= 'maps' then
                        self[k] = v
                    end
                end
            end

            return self
        end
    }
)

function Window:get_position()
    local ui_height = self:ui_height()
    local ui_width = self:ui_width()

    local float_width, float_height = self.width, self.height
    local row, col = 0, 0
    -- print('position: ' .. require'inspect'.inspect(self.position))
    -- print(fmt('ui_width: %s, ui_height: %s', ui_width, ui_height))
    -- print(fmt('width: %s, height: %s', float_width, float_height))

    if type(self.position) == 'string' then
        if self.position == 'center' then
            col = (ui_width - float_width) / 2
            row = (ui_height - float_height) / 2
        elseif self.position == "top-left" then
            row, col = 0, 0
        elseif self.position == "top-right" then
            row, col = 0, ui_width - float_width
        elseif self.position == "bottom-left" then
            row, col = ui_height - float_height, 0
        elseif self.position == "bottom-right" then
            row, col = ui_height - float_height, ui_width - float_width
        else
            error("Invalid corner specified: " .. (self.position or 'nil'))
        end
    else
        if self.position.relative then
            row, col = self.relative.row*ui_height, self.relative.col*ui_width
        elseif self.position.absolute then
            row, col = unpack(self.position.absolute)
        else
            error('Position not set')
        end
    end
    -- print(fmt('get_pos: row: %s, col: %s', row, col))
    return row, col
end

function Window:set_position()
    self.row, self.col = self:get_position()
    self.row = math.floor(self.row)
    self.col = math.floor(self.col)
    -- print('set_pos:')
    -- print(fmt('set pos: row: %s, col: %s', self.row, self.col))
end

function Window:redraw()
    self:set_size()
    self:set_position()
    vim.api.nvim_buf_set_option(self.buf, 'modifiable', self.modifiable)

    vim.api.nvim_win_set_config(self.id, self:options())
end

Buffer = {}
function Buffer.mapping_exists(bufnr, mode, lhs)
    local mappings = vim.api.nvim_buf_get_keymap(bufnr, mode)
    for _, map in ipairs(mappings) do
        if map.lhs == lhs then
            return true
        end
    end
    return false
end

function Buffer.unmap(bufnr)
    local modes = {'n', 'v', 'i', 'x', 's', 'o', 'c', 't'}
    for _,mode in ipairs(modes) do
        local mappings = vim.api.nvim_buf_get_keymap(bufnr, mode)
        for _, map in ipairs(mappings) do
            vim.api.nvim_buf_del_keymap(0, mode, map.lhs)
        end
    end
end

-- create mappings for the move functions
vim.api.nvim_set_keymap('n', '<C-S-Up>', ':lua Window.up()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-Down>', ':lua Window.down()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-Left>', ':lua Window.left()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-Right>', ':lua Window.right()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-k>', ':lua Window.snap_up()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-j>', ':lua Window.snap_down()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-l>', ':lua Window.snap_left()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-h>', ':lua Window.snap_right()<CR>', { noremap = true, silent = true })



vim.api.nvim_create_user_command("WinUp", ':lua Window.up()', {})
vim.api.nvim_create_user_command("WinDown", ':lua Window.down()', {})
vim.api.nvim_create_user_command("WinLeft", ':lua Window.left()', {})
vim.api.nvim_create_user_command("WinRight", ':lua Window.right()', {})
vim.api.nvim_create_user_command("WinSnapUp", ':lua Window.up()', {})
vim.api.nvim_create_user_command("WinSnapDown", ':lua Window.down()', {})
vim.api.nvim_create_user_command("WinSnapLeft", ':lua Window.left()', {})
vim.api.nvim_create_user_command("WinSnapRight", ':lua Window.right()', {})

-- handle_link()
-- ag  '\- \[.\]' | cut -d : -f1,2 | sed 's/:/ /g'                                                                                                                   22.3.0 󰌠 3.12.4 (python3.12)

--setup the buffer with links and test
-- setup_buffer_with_links()
return Window
