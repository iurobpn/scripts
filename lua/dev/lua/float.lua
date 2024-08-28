require('class')
local Log = require('dev.lua.log')
local fmt = string.format
local log = Log('float')

Window = {
    relative = 'editor',
    redraw = false, -- check if the window is already oppened with sizes and position
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
    modifiable = true,
    close = false, -- close current window when it is being floated

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

function Window.update_clock(buf, t_period)
    if not t_period then
        t_period = 1000
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
            Window.update_clock(buf, t_period)
        end
    end, t_period) -- 60000 ms = 1 min
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

function Window.open_clock(t)
    t = t or 1000
    local win = Window.popup()
    win:config(
        {
            title = 'clock',
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
        --     maps = {
        --         n = {
        --             {
        --                 keys = ':bnext<CR>',
        --                 cmd = ' ',
        --                 opts = { noremap = true, silent = true }
        --             },
        --             {
        --                 keys = ':bprev<CR>',
        --                 cmd = '<Nop>',
        --                 opts = { noremap = true, silent = true }
        --             },
        --             {
        --                 keys = ':buffer<CR>',
        --                 cmd = '<Nop>',
        --                 opts = { noremap = true, silent = true }
        --             },
        --         },
        --     }
        }

    )
    -- vim.api.nvim_buf_set_keymap(buf, 'n', ':bnext', '<Nop>', { noremap = true, silent = true })
    -- vim.api.nvim_buf_set_keymap(buf, 'n', ':bprev', '<Nop>', { noremap = true, silent = true })
    -- vim.api.nvim_buf_set_keymap(buf, 'n', ':buffer', '<Nop>', { noremap = true, silent = true })
    win:open()
    vim.cmd('wincmd p')
    print('clock win: ' .. require'inspect'.inspect(win))
    win:params()
    win.update_clock(win.buf, t)
end
function Window.close_clock()
    -- win = Window.floats[win.id]
    -- win:close()
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
            print(k, v)
            opts[k] = v
        end
    end
    win.config(opts)

    return win
end

function Window:set_size()
    if self.size.relative then
        self.width = math.floor(self:ui_cols()*self.size.relative.width)
        self.height = math.floor(self:ui_rows()*self.size.relative.height)
    elseif self.size.absolute then
        self.width = self.size.absolute.width
        self.height = self.size.absolute.height
    else
        error('Size not set size')
    end
    return self.width, self.height
end


function Window:add_map(mode, keys, cmd, opts)
    table.insert(self.maps[mode], {keys = keys, cmd = cmd, opts = opts})
end

function Window:params()
    local width, height = self.width, self.height
    local col, row = self.col, self.row
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

function Window.close()
    win_id = vim.fn.win_getid()
    if win_id and not Window.is_floating(win_id) then
        print("Current win is not a float.")
        win_id = nil
        for id, w in pairs(Window.floats) do
            if Window.is_floating(id) then
                win_id = id
                print('float win_id found :', win_id)
                break
            end
        end
        print('floats arent floats?') 
    end
    if win_id then
        vim.api.nvim_win_close(win_id, true)
        Window.floats[win_id] = nil
        local buf = vim.api.nvim_get_current_buf()
        Buffer.unmap(buf)
    else
        print("No floating window to close.")
    end
    print('floats: ' .. require'inspect'.inspect(Window.floats))
    -- if win_id and vim.api.nvim_win_is_valid(win_id) then
    --     --remove mapping
    --     -- get current buffer
    --     local opt = vim.api.nvim_win_get_config(win_id)
    --     opt.focusable = true
    --     opt.width = 1
    --     opt.height = 1
    --     opt.row = 0
    --     opt.col = 0
    --     opt.relative = 'editor'
    --     vim.api.nvim_win_set_config(win_id, opt)
    --     local buf = vim.api.nvim_get_current_buf()
    --     Buffer.unmap(buf)
    --     vim.api.nvim_win_close(win_id, true)
    -- else
    --     print("No floating window to close.")
    -- end
    -- Window.floats[win_id] = nil -- morre disgrama!!!
end

function Window:open()
    if not self.redraw then
        self:set_size()
        self:set_position()
    end

    local opts = {
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

    if not self.cursor then
    --     vim.opt.guicursor = vim.o.background
        vim.cmd(fmt('highlight Cursor guifg=%s guibg=%s', vim.o.background, vim.o.background))
    end

    local id = nil
    if self.current then
        self.id, self.buf, self.filename = Window.get_current()
        self.close = true
        id = self.id
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

    if id ~= nil and self.close then
        vim.api.nvim_win_close(id, false)
    end




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
    print('floats: ' .. require'inspect'.inspect(Window.floats))

    self.redraw = true
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
    win:open()
    win:params()
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
        Buffer.del_keymaps(buf)
        vim.api.nvim_win_close(winid, true)
    else
        print("No floating window to close.")
    end
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
)

function Window:set_position()
    local ui_height = self:ui_rows()
    local ui_width = self:ui_cols()

    local float_width, float_height = self.width, self.height
    local row, col = 0, 0

    print('set position to: ' .. require'inspect'.inspect(self.position))
    print('set pos: width: ' .. float_width .. ' height: ' .. float_height)
    print('set pos: ui_width: ' .. ui_width .. ' height: ' .. ui_height)

    if type(self.position) == 'string' then
        if self.position == 'center' then
            row = math.floor((ui_width - float_width) / 2)
            col = math.floor((ui_height - float_height) / 2)
        elseif self.position == "top-left" then
            row, col = 0, 0
        elseif self.position == "top-right" then
            print('set position to top-right: ', 0, ui_width - float_width)
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
    self.row = row
    self.col = col
end

Buffer = {}
function Buffer.safe_unmap(bufnr, mode, lhs)
    if Buffer.mapping_exists(bufnr, mode, lhs) then
        vim.api.nvim_buf_del_keymap(bufnr, mode, lhs)
    end
end
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



-- handle_link()
-- ag  '\- \[.\]' | cut -d : -f1,2 | sed 's/:/ /g'                                                                                                                   22.3.0 󰌠 3.12.4 (python3.12)

--setup the buffer with links and test
-- setup_buffer_with_links()
return Window
