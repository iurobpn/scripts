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
        Buffer.load_file(bufnr, filename, false)
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
    if not buf then
        print("No buffer provided")
        return
    end
    if not filename or #filename == 0 then
        error('No filename provided')
        return
    end
    if not buf then
        buf = vim.api.nvim_create_buf(true, false)
    end
    vim.api.nvim_buf_set_name(buf, filename)
    vim.api.nvim_command("edit " .. filename)
end

function Buffer.append_lines(buf, content)
    local line_start = vim.api.nvim_buf_line_count(buf)
    content = Buffer.check_content(content)
    vim.api.nvim_buf_set_lines(buf, line_start, -1, true, content) -- append to file

end
function Buffer.set_lines(buf, line_start, line_end, content)
    if not buf then
        print("No buffer provided")
        return
    end
    if line_start == nil then
        line_start = 0
    end
    content = Buffer.check_content(content)
    vim.api.nvim_buf_set_lines(buf, line_start, -1, true, content) -- overwrite file
end

function Buffer.load_file(buf,filename,is_saved)-- Check if the file exists
    if not is_saved then
        is_saved = true
    end
    if vim.fn.filereadable(filename) == 1 then
        -- Read file content
        local file_content = vim.fn.readfile(filename)

        -- Load the file content into the buffer
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, file_content)

        -- Optionally set the buffer name (not mandatory)
        if is_saved then
            vim.api.nvim_buf_set_name(buf, filename)
        end

        -- Set the filetype (optional, if you need it)
        vim.api.nvim_set_option_value('filetype', vim.fn.fnamemodify(filename, ":e"), {buf = buf, scope = "local"})

        return buf -- Return the buffer number
    else
        print("File not found: " .. filename)
        return nil
    end
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

M.Buffer = Buffer

return M
