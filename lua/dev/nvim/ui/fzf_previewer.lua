-- -----------------------------------------
-- Author: Iuro Nascimento
-- Date 2024-09-15 13:05
-- Description: Custom previewer for fzf-lua
-- -----------------------------------------

-- local fzf_lua = require("fzf-lua")
local builtin = require("fzf-lua.previewer.builtin")

local utils = require("utils")
local fs = require("dev.lua.fs")


local M = {}

-- Inherit from "base" instead of "buffer_or_file"
local Previewer = builtin.buffer_or_file:extend()


function Previewer:new(o, opts, fzf_win)--i
    print('creating new previewer')
    Previewer.super.new(self, o, opts, fzf_win)
    setmetatable(self, Previewer)
    return self
end

function Previewer:populate_preview_buf(entry_str)

    local tmpbuf = self:get_tmp_buffer()

    local path, line_nr = utils.get_file_line(entry_str)
    if path == nil then
        error('line parsed does not have a file and line number')
    end

    self.load_buffer(tmpbuf, path)
    self:set_preview_buf(tmpbuf)

    -- set cursor and cursorline
    local winid = self.win.preview_winid
    vim.api.nvim_win_set_cursor(winid, {line_nr, 0})
    vim.api.nvim_win_set_option(winid, 'cursorline', true)

    self.set_syntax(winid, path)
end

function Previewer.set_syntax(winid,file)
    local ft = fs.get_file_extension(file)
    if ft == 'md' then
        ft = 'markdown'
    end
    vim.api.nvim_win_set_option(winid, 'filetype', ft)
end


function Previewer:set_winopts(opts)
    self.added_winopts = opts
end
-- Disable line numbering and word wrap
function Previewer:gen_winopts()
    local new_winopts = {
        wrap           = false,
        number         = true,
        relativenumber = false,
        cursorline     = true,
        title_pos      = "center",
        -- cursorline        = true,
    }
    self.winopts = vim.tbl_extend("force", self.winopts, new_winopts)
    if self.added_winopts == nil then
        return self.winopts
    end
    return vim.tbl_extend("force", self.winopts, self.added_winopts)
end

function Previewer.load_buffer(tmpbuf, path)
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
    -- vim.cmd('filetype plugin on')
    -- vim.cmd('filetype on')
    -- vim.cmd('syntax on')
    vim.cmd('filetype detect')
end

function Previewer.load_buffer_line(tmpbuf, path, line_nr)
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
M.Previewer = Previewer

return M
