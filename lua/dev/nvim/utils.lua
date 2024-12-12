local utils = require('utils')
local M = {}

function M.get_context(filename, line_num, size)
    if not filename then
        print('Error: filename is required to get the file context')
        return
    end
    local bufnr
    if not M.is_file_loaded(filename) then
        -- load the file to a new buffer
        bufnr = vim.api.nvim_create_buf(false, true)
        Buffer.load(bufnr, filename)
    else
        bufnr = vim.fn.bufnr(filename)
    end
    if not line_num then
        print('Error: line_num is required to get the file context')
        return
    end
    if not size then
        size = 3
    end

    -- Get the current file context (surrounding lines)
    local context_lines_before = size -- Show 3 lines before the current line
    local context_lines_after = size  -- Show 3 lines after the current line

    local last_line = vim.api.nvim_buf_line_count(bufnr);
    local start_line = math.max(0, line_num - context_lines_before - 1)
    local end_line = math.min(last_line, line_num + context_lines_after)
    local lines  = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)

    return lines
end

function M.is_file_loaded(filepath)
    -- Get the buffer number for the file (returns -1 if the file is not loaded)
    local bufnr = vim.fn.bufnr(filepath)

    -- Check if the buffer number is valid and if the buffer is listed (loaded)
    if bufnr ~= -1 and vim.fn.buflisted(bufnr) == 1 then
        return true
    end

    return false
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

function Buffer.load(buf,filename)
    if buf ~= nil or not Buffer.is_valid(buf) then
        print("No buffer provided")
        return
    end
    if not filename or #filename == 0 then
        error('No filename provided')
        return
    end
    vim.api.nvim_buf_set_name(buf, filename)
    vim.api.nvim_command("edit " .. filename)
end

function Buffer.append(buf, content)
    if not Buffer.is_valid(buf) then
        print("No buffer provided")
        return
    end
    local line_start = vim.api.nvim_buf_line_count(buf)
    content = Buffer.check_content(content)
    vim.api.nvim_buf_set_lines(buf, line_start, -1, true, content) -- append to file
end

---set lines in buffer
---@param buf number
---@param line_start number
---@param line_end number
---@param content string
function Buffer.set_lines(buf, content, line_start, line_end, strict)
    if buf ~= nil or not Buffer.is_valid(buf) then
        print("No buffer provided")
        return
    end
    if line_start == nil then
        line_start = 0
    end
    if line_end == nil then
        line_end = -1
    end
    if strict == nil then
        strict = false
    end
    content = Buffer.check_content(content)
    vim.api.nvim_buf_set_lines(buf, line_start, line_end, strict, content) -- overwrite file
end

function Buffer.check_content(content)
    if type(content) == 'string' then
        content = vim.split(content, '\n')
        if type(content) == 'string' then
            content = {content}
        end
    end
    return content
end

-- preserve marks
function Buffer.set_text(buf, start_row, start_col, end_row, end_col, content)
    content = Buffer.check_content(content)
    vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, content)
end

function Buffer.new(listed, scratch)
    if listed == nil then
        listed = true
    end
    if scratch == nil then
        scratch = false
    end
    return vim.api.nvim_create_buf(listed, scratch)  -- false for listed, true for scratch
end

-- add acratch buffer
function Buffer.scratch(content)
    local buf = Buffer.new(false, true)
    Buffer.set_lines(buf, content)
    return buf
end

function Buffer.delete(buf)
    if not Buffer.is_valid(buf) then
        return
    end
    vim.api.nvim_buf_delete(buf, {force = true})
end

function Buffer.get_lines(buf, start, finish, strict)
    if not Buffer.is_valid(buf) then
        return
    end
    if not start then
        start = 0
    end
    if not finish then
        finish = -1
    end
    if strict == nil then
        strict = true
    end
    return vim.api.nvim_buf_get_lines(buf, start, finish, strict)
end

function Buffer.get_text(buf, start_row, start_col, end_row, end_col)
    if not Buffer.is_valid(buf) then
        return
    end
    return vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col)
end

function Buffer.get_name(buf)
    if not Buffer.is_valid(buf) then
        return
    end
    return vim.api.nvim_buf_get_name(buf)
end

function Buffer.get_option(buf, option)
    if not Buffer.is_valid(buf) then
        return
    end
    return vim.api.nvim_get_option_value(option , { buf = buf})
end

function Buffer.set_option(buf, option, value)
    if not Buffer.is_valid(buf) then
        return
    end
    vim.api.nvim_set_option_value(option, value, { buf = buf } )
end

-- checki if buffer is valid
function Buffer.is_valid(buf)
    if buf == nil or not vim.api.nvim_buf_is_valid(buf) then
        return false
    end
    return true
end

M.Buffer = Buffer

return M
