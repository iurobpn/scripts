local M = {
    query = require('dev.lua.tasks.query'),
    parser = require('dev.lua.tasks.parser'),
    Indexer = require('dev.lua.tasks.indexer').Indexer,
    fzf = require('dev.lua.tasks.fzf'),
    views = require('dev.lua.tasks.views'),
}

local tasks = {
    json = nil,
    tab = nil
}
M.tasks = tasks
-- make recurrent taks done and add completion date
function M.recurrent_done()
    local cursor_orig = vim.api.nvim_win_get_cursor(0)
    -- get current line from buffer
    local line = vim.api.nvim_get_current_line()
    local is_recurring = M.parser.get_param_value(line, 'repeat')
    if not is_recurring then
        vim.notify('Task is not recurring')
        return false
    end
    local line_next
    if is_recurring == 'every month' then
        local due_date = M.parser.get_param_value(line, 'due')
        if not due_date then
            vim.notify('Task is not due')
            return false
        end

        local year, month = string.match(line, '(%d+)%-(%d+)%-%d+')
        month = tonumber(month)
        if month == nil then
            vim.notify('No month found in due date')
            return false
        end
        month = month + 1
        if month > 12 then
            month = 1
            year = year + 1
        end
        local y_month = string.format('%s-%02d', year, month)
        line_next = line:gsub('(%[due::%s*)%d+%-%d%d(%-%d+[^%]]*%])', string.format('%s%s%s', '%1', y_month, '%2'))

        vim.notify('Task is recurring every month')
    end
    --
    line = string.gsub(line, '(%- %[.?%])', '- [x]')
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line_number = cursor[1]
    -- write the new line to the buffer
    vim.api.nvim_set_current_line(line .. ' [completion:: ' .. os.date('%Y-%m-%d %H:%M:%S') .. ']')
    if line_next then
        if line_number > -1 then
            line_number = line_number - 1
        end
        line_next = string.gsub(line_next, '(%- %[.?%])', '- [ ]')
        vim.api.nvim_buf_set_lines(0, line_number, line_number, false, {line_next})
    end
    -- set the cursor back to the original line
    vim.api.nvim_win_set_cursor(0, cursor_orig)
    vim.notify('Task marked as done')
    return true
end

M.search = function(tag, ...)
    return M.views.search(tag, ...)
end

-- Add a command to run index function
vim.api.nvim_create_user_command('Index', 'lua require"dev.lua.tasks.indexer".index()',
    {
        nargs = 0,
        desc = 'Index note tasks  and save into json file'
    }
)

return M
