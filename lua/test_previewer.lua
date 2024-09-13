local fzf_lua = require("fzf-lua")
local builtin = require("fzf-lua.previewer.builtin")

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
        local line = task_splited[2]
    
  vim.api.nvim_buf_set_lines(tmpbuf, 0, -1, false, {
    string.format("SELECTED FILE: %s", entry_str)
  })
  self:set_preview_buf(tmpbuf)
  self.win:update_scrollbar()
end

-- Disable line numbering and word wrap
function MyPreviewer:gen_winopts()
  local new_winopts = {
    wrap    = false,
    number  = false
  }
  return vim.tbl_extend("force", self.winopts, new_winopts)
end

fzf_lua.fzf_exec("cat files_line.txt", {
  previewer = MyPreviewer,
  prompt = "Select file> ",
})
