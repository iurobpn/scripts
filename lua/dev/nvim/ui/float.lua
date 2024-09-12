if vim == nil then
    error('This is a neovim module, it can only be load from neovim')
end
local utils = require('utils')
require('class')
local Log = require('dev.lua.log').Log

local Buffer = require('dev.nvim.utils').Buffer

local fmt = string.format

-- local log = Log('float')

local Window = {
    -- static ----------------------
    id_count = 0,
    floats = {}, -- list of open floats, indexed by the wim win id
    hidden = {}, -- list of windows close using toggle, indexed by the idx inner index
    --------------------------------

    vid = nil, -- vim id
    idx = -1,  -- index of the window inside the module

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
    -- style = 'minimal',
    border = 'rounded',

    content = '',
    filename = '',
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
        cmd = ':WinToggle<CR>',
        opts = { noremap = true, silent = true }
    },
    current = false, --get current windows buffer
    buffer = {
        listed = true,
        scratch = false,
    },
    fullscreem = false,

    is_hidden = false,

    focusable = true,
    modifiable = true,
    close_current = false, -- close current window when it is being floated
    option = {
        swapfile = true,
        buftype = '', -- set the buffer type prompt and terminal are interesting types
        bufhidden = '',
        bulisted = true,

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

    return width, height
end

function Window:set_size()
    self.width, self.height = self:get_size()
    self.width = math.floor(self.width)
    self.height = math.floor(self.height)
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

function Window:close(vid)
    local win_id = 0
    if self == nil and vid == nil then
        win_id = vim.fn.win_getid()
    elseif vid == nil then
        win_id = self.vid
    elseif vid >= 0 then
        win_id = vid
        Window.set_win(win_id)
    end
    if win_id ~= nil and Window.is_floating(win_id) then
        local buf = vim.api.nvim_get_current_buf()
        Buffer.unmap(buf)
        vim.api.nvim_win_close(win_id, true)
        Window.floats[win_id] = nil
    else
        vim.notify("Current window is either invalid (id) or is not a float to close.")
    end
end

function Window.set_win(vid)
    if vim.api.nvim_win_is_valid(vid) then
        vim.api.nvim_set_current_win(vid)
    else
        vim.notify("Invalid window ID")
    end
end

function Window:get_options()

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
    for vid, win in pairs(Window.floats) do
        if win ~= nil and Window.is_floating(vid) then
            win:close()
        end
    end
end

function Window:open()
    self:set_size()
    self:set_position()

    -- if not self.cursor then
    -- --     vim.opt.guicursor = vim.o.background
    --     vim.cmd(fmt('highlight Cursor guifg=%s guibg=%s', vim.o.background, vim.o.background))
    -- end

    if self.current then -- use current buffer
        self.vid, self.buf, self.filename = Window.get_current()
    elseif self.buf then -- use the buffer already set

    elseif self.vid ~= nil then -- use the window id already set. It must be a float
        self.buf, self.filename = Window.get_window(self.vid)
    else
        if not self.buf then
            -- create new buffer
            self.buf = Buffer.new(self.buffer.listed, self.buffer.scratch)
        end
        if self.filename ~= nil and #self.filename > 0 then -- create a buffer to load the file
            Buffer.load(self.buf,self.filename)
        elseif self.content ~= nil and #self.content > 0 then -- create a buffer and load the content into it
            Buffer.set_lines(self.buf, 0,  -1, self.content) -- write to buffer
        end
    end

    local opts = self:get_options()

    if not self.buf then
        vim.notify("No buffer to open")
        return
    end
    vim.api.nvim_buf_set_option(self.buf, 'modifiable', self.modifiable)

    if self.current then
        vim.api.nvim_win_set_config(self.vid, opts)
    else
        self.vid = vim.api.nvim_open_win(self.buf, true, opts)
    end

    if vid ~= nil and self.close_current or opts.close_current then
        vim.api.nvim_win_close(self.vid, false)
    end
    if self.idx < 0 then
        self.idx = Window.id_count
        Window.id_count = Window.id_count + 1
    end

    if not self.modifiable then
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
    Window.floats[self.vid] = self
end


function Window.get_window(vid)
    -- Get the current window and buffer
    local buf, filename = nil, nil
    if Window.is_floating(vid) then
        buf = vim.api.nvim_win_get_buf(vid)
        filename = vim.api.nvim_buf_get_name(buf)
    else
        vim.notify('window is not a float')
    end

    return buf, filename
end

function Window.get_current()
    -- Get the current window and buffer
    local vid = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(buf)

    return vid, buf, filename
end

-- no link to the file, like in :r filename
function Window:read(filename)
    vim.api.nvim_buf_call(self.buf, function()
        vim.api.nvim_command("edit " .. filename)
    end)
end

function Window.is_floating(vid)
    return vid ~= nil and vim.api.nvim_win_is_valid(vid) and vim.api.nvim_win_get_config(vid).relative ~= ''
end


function Window.snap_down()
    local win_id = vim.fn.win_getid()
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        vim.noitfy("Current window is not floating to snap down.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.row = vim.api.nvim_get_option("columns") - win_config.height
    vim.api.nvim_win_set_config(win_id, win_config)
end

function Window.snap_up()
    local win_id = vim.fn.win_getid()
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        vim.notify("Current window is not floating to snap up.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.row = 0
    vim.api.nvim_win_set_config(win_id, win_config)
end

function Window.snap_right()
    local win_id = vim.fn.win_getid()
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        vim.notify("Current window is not floating to snap right.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.col = vim.api.nvim_get_option("columns") - win_config.width
    vim.api.nvim_win_set_config(win_id, win_config)
end

function Window.snap_left()
    local win_id = vim.fn.win_getid()
    if not win_id or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        vim.notify("Current window is not floating to snap left.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.col = 0
    vim.api.nvim_win_set_config(win_id, win_config)
end

function Window.fullscreen()
    local win_id = vim.fn.win_getid()
    if win_id == nil or not vim.api.nvim_win_is_valid(win_id) or not Window.is_floating(win_id) then
        vim.notify("Current window is not floating to be in fullscreen.")
        return
    end

    local win_config = vim.api.nvim_win_get_config(win_id)
    win_config.row = 0
    win_config.col = 0
    win_config.width = vim.api.nvim_get_option("columns")
    win_config.height = vim.api.nvim_get_option("lines")-5
    vim.api.nvim_win_set_config(win_id, win_config)
    Window.floats[win_id].fullscreen = true
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

function handle_link()
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
            self.idx = Window.new_id()

            return self
        end
    }
)

function Window.new_id()
    Window.id_count = Window.id_count + 1
    return Window.id_count
end

-- calculate the position of the float window
function Window:get_position()
    local ui_height = self:ui_height()
    local ui_width = self:ui_width()

    local float_width, float_height = self.width, self.height
    local row, col = 0, 0

    if type(self.position) == 'string' then
        if self.position == 'center' then
            col = (ui_width - float_width) / 2
            row = (ui_height - float_height) / 2
        elseif self.position == "top-left" then
            row, col = 1, 0
        elseif self.position == "top-right" then
            row, col = 1, ui_width - float_width
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
            row = self.position.absolute.row
            col = self.position.absolute.col
        else
            error('Position not set')
        end
    end

    return row, col
end

function Window:set_position()
    self.row, self.col = self:get_position()
    self.row = math.floor(self.row)
    self.col = math.floor(self.col)
end

function Window:redraw()
    local vid = nil
    if not self then
        vid = vim.fn.win_getid()
        self = Window.floats[vid]
        if not self then
            vim.notify("Current window is not a float to be redrawn.")
            return
        end
    end

    self:set_size()
    self:set_position()
    vim.api.nvim_buf_set_option(self.buf, 'modifiable', self.modifiable)

    vim.api.nvim_win_set_config(self.vid, self:get_options())
end

function Window.toggle_fullscreen()
    local win_id = vim.fn.win_getid()
    -- local win_config = vim.api.nvim_win_get_config(win_id)
    if Window.floats == nil or Window.floats[win_id] == nil then
        vim.notify("Current window is not a float to be toggled.")
        return
    end
    if  Window.floats[win_id].fullscreen then
        Window.floats[win_id].fullscreen = false
        Window.redraw()
    else
        Window.fullscreen()
    end
end

function Window.toggle()
    local vid = vim.fn.win_getid()
    if Window.floats[vid] then
        local win = Window.floats[vid]
        if not win then
            vim.notify("Current window is not a float to be toggled.")
            return
        end
        Window.hidden[win.idx] = win
        win:close()
        Window.floats[vid] = nil
    else
        local n = utils.numel(Window.hidden)
        local win = nil
        local idx = -1
        if n > 0 then
            for i, w in ipairs(Window.hidden) do
                idx = i
                win = w
                break
            end
            if win == nil then
                vim.notify("No window to toggle")
                return
            end
            win:open()
            Window.floats[win.vid] = win
            Window.hidden[idx] = nil
        else
            local win = Window()
            win:open()
            Window.floats[win.vid] = win
        end
    end
end

vim.api.nvim_create_user_command("WinUp",               ':lua dev.nvim.ui.float.Window.up()',                {})
vim.api.nvim_create_user_command("WinDown",             ':lua dev.nvim.ui.float.Window.down()',              {})
vim.api.nvim_create_user_command("WinLeft",             ':lua dev.nvim.ui.float.Window.left()',              {})
vim.api.nvim_create_user_command("WinRight",            ':lua dev.nvim.ui.float.Window.right()',             {})
vim.api.nvim_create_user_command("WinSnapUp",           ':lua dev.nvim.ui.float.Window.up()',                {})
vim.api.nvim_create_user_command("WinSnapDown",         ':lua dev.nvim.ui.float.Window.down()',              {})
vim.api.nvim_create_user_command("WinSnapLeft",         ':lua dev.nvim.ui.float.Window.left()',              {})
vim.api.nvim_create_user_command("WinSnapRight",        ':lua dev.nvim.ui.float.Window.right()',             {})
vim.api.nvim_create_user_command("WinToggleFullScreen", ':lua dev.nvim.ui.float.Window.toggle_fullscreen()', {})
vim.api.nvim_create_user_command("WinFullScreen",       ':lua dev.nvim.ui.float.Window.fullscreen()',        {})
vim.api.nvim_create_user_command("WinRedraw",           ':lua dev.nvim.ui.float.Window.redraw()',            {})
vim.api.nvim_create_user_command("WinToggle",           ':lua dev.nvim.ui.float.Window.toggle()',            {})

-- create mappings for the move functions
vim.api.nvim_set_keymap('n', '<C-S-Up>',    ':WinUp<CR>',               { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-Down>',  ':WinDown<CR>',             { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-Left>',  ':WinLeft<CR>',             { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-S-Right>', ':WinRight<CR>',            { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-k>',       ':WinSnapUp<CR>',           { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-j>',       ':WinSnapDown<CR>',         { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-l>',       ':WinSnapRight<CR>',        { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-h>',       ':WinSnapLeft<CR>',         { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'º',           ':WinToggleFullScreen<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'Ç',           ':WinToggle<CR>',           { noremap = true, silent = true })
-- handle_link()
-- ag  '\- \[.\]' | cut -d : -f1,2 | sed 's/:/ /g' | sort | uniq

--setup the buffer with links and test
-- setup_buffer_with_links()

local M = {
    Window = Window
}

return M
