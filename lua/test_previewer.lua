local fzf_lua = require("fzf-lua")
local builtin = require("fzf-lua.previewer.builtin")

local fs = require("dev.lua.fs")

M = {}

-- Inherit from "base" instead of "buffer_or_file"
local MyPreviewer = builtin.base:extend()

function MyPreviewer:new(o, opts, fzf_win)
    MyPreviewer.super.new(self, o, opts, fzf_win)
    setmetatable(self, MyPreviewer)
    return self
end

function MyPreviewer:populate_preview_buf(entry_str)
    local tmpbuf = self:get_tmp_buffer()

    local task_splited = vim.split(entry_str, ':')
    if task_splited == nil then
        error('task_splited is nil')
    end
    local path = task_splited[1]
    local line_nr = tonumber(task_splited[2])

    self.load_buffer(tmpbuf, path)
    self:set_preview_buf(tmpbuf)

    -- set cursor and cursorline
    local winid = self.win.preview_winid
    vim.api.nvim_win_set_cursor(winid, {line_nr, 0})
    vim.api.nvim_set_option_value('cursorline', true, {win = winid, scope = "local"})

    self.set_syntax(winid, path)
end

function MyPreviewer.set_syntax(winid,file)
    local ft = fs.get_file_extension(file)
    if ft == 'md' then
        ft = 'markdown'
    end
    vim.api.nvim_set_option_value('filetype', ft, {win = winid, scope = "local"})
end

-- Disable line numbering and word wrap
function MyPreviewer:gen_winopts()
    local new_winopts = {
        wrap           = false,
        number         = true,
        relativenumber = false,
        cursorline     = true,
        title_pos      = "center",
        -- cursorline        = true,
    }
    return vim.tbl_extend("force", self.winopts, new_winopts)
end

function MyPreviewer.load_buffer(tmpbuf, path)
    -- local path = entry_str
    local fd = io.open(path, 'r')
    if fd == nil then
        print('could not open file ' .. path)
        return
    end

    local lines = {}
    local k = 1
    for line in fd:lines() do
        table.insert(lines, line)
        k = k + 1
    end

    vim.api.nvim_buf_set_lines(tmpbuf, 0, -1, false, lines)
    vim.api.nvim_buf_set_name(tmpbuf, path)
    vim.cmd('filetype plugin on')
    vim.cmd('filetype on')
    vim.cmd('syntax on')
    vim.cmd('filetype detect')
    print('filetype: ' .. vim.bo.filetype)
end

function MyPreviewer.load_buffer_line(tmpbuf, path, line_nr)
    -- local path = entry_str
    local fd = io.open(path, 'r')
    if fd == nil then
        print('could not open file ' .. path)
        return
    end

    local lines = {}
    local line_c = ' ops, line not selected'
    local k = 1
    for line in fd:lines() do
        if line_nr == line then
            line_c = line
            break
        end
        k = k + 1
    end
    table.insert(lines, line_c)

    vim.api.nvim_buf_set_lines(tmpbuf, 0, -1, false, lines)
    vim.api.nvim_buf_set_name(tmpbuf, path)
end

function M.search()
    fzf_lua.fzf_exec("fd .lua -tf | files_line.awk", {
        previewer = MyPreviewer,
        prompt = "Task> ",
        -- preview = {
        --     syntax          = true,
        --     winopts = {                       -- builtin previewer window options
        --         number            = true,
        --         relativenumber    = false,
        --         cursorline        = true,
        --         cursorlineopt     = 'both',
        --         cursorcolumn      = false,
        --         signcolumn        = 'no',
        --         list              = false,
        --         foldenable        = false,
        --         foldmethod        = 'manual',
        --     },
        -- },
    })
end
M.MyPreviewer = MyPreviewer
return M

