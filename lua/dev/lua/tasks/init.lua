local json = require('cjson')
local utils = require('utils')
local M = {
    query = require('dev.lua.tasks.query'),
    parser = require('dev.lua.tasks.parser'),
    Indexer = require('dev.lua.tasks.indexer').Indexer,
    fzf = require('dev.lua.tasks.fzf'),
    views = require('dev.lua.tasks.views'),
}

local tasks = {
    json = nil,
    tab = nil,
    ns_id = nil,
    jq_line = nil,
    inserted_lines = nil

}
local jq_fix = {
    ns_id = nil,
    vid = nil,  -- Variable to store the floating window ID,
    bufnr = nil,   -- Variable to store the buffer number for the floating window,
    line = nil,          -- Variable to store the line number with the jq command,
}
local jq = {
    ns_id = nil,
    vid = nil,  -- Variable to store the floating window ID,
    bufnr = nil,   -- Variable to store the buffer number for the floating window,
    line = nil,          -- Variable to store the line number with the jq command,
}
M.tasks = tasks
M.jq = jq
M.jq_fix = jq_fix
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

function M.get_cmd()
    local line = vim.api.nvim_get_current_line()
    local cmd = line:match('%{%{%s*jq: (.*)%}%}')
    if not cmd then
        return
    end
    cmd = 'jq ' .. cmd
    return cmd
end

function M.get_jq_lines()
    local cmd = M.get_cmd()
    local q = M.query.Query()
    local lines = q:run(cmd)
    -- M.jq.line = vim.api.nvim_win_get_cursor(0)[1]
    return lines
end

function M.ShowJqResult()
    -- Create a namespace for your extmarks
    if not M.ns_id then
        M.ns_id = vim.api.nvim_create_namespace('JqResultNamespace')
    end
    local lines = M.get_jq_lines()
    if lines == nil then
        return
    end
    -- Get the current buffer number
    local bufnr = vim.api.nvim_get_current_buf()

    -- Get the current cursor position (line and column)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local start_line = cursor_pos[1] - 1  -- Adjust for Lua's 0-indexing

    -- Iterate over the output lines and set virtual text
    for i, line in ipairs(lines) do
        if line ~= '' then
            vim.api.nvim_buf_set_extmark(bufnr, M.ns_id, start_line + i - 1, 0, {
                virt_text = { { line, 'Comment' } },  -- You can choose a different highlight group
                virt_text_pos = 'eol',
            })
        end
    end
end

function M.tostring(task)
-- description = "ver inicio de capitulos ",
--   filename = "/home/gagarin/sync/obsidian/Thesis.md",
--   id = 27,
--   line_number = 53,
--   status = "not started",
--   tags = { "#today" }
    local status
    if task.status == 'not started' then
        status = ' '
    elseif task.status == 'in progress' then
        status = '.'
    elseif task.status == 'done' then
        status = 'x'
    end

    local mtags = ''
    if task.metatags then
        for k,v in pairs(task.metatags) do
            mtags = mtags .. string.format('[%s:: %s]', k, v)
        end
    end
    local due = ''
    if task.due ~= nil then
        due = string.format('[%s:: %s]', 'due', task.due)
    end
    local tags = table.concat(task.tags,' ')
    local line = string.format('- [%s] %s %s %s %s', status, task.description, tags, due, mtags)
    return line
end

function M.mtag_to_string(mtag,val)
    return string.format('[%s:: %s]', mtag, value)
end

function M.UpdateJqFloat()
    if not vim.api.nvim_buf_is_valid(0) then return end

    local bufnr = vim.api.nvim_get_current_buf()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local current_line = cursor_pos[1]  -- Lua uses 1-indexing for lines

    -- Get the content of the current line
    local line_content = vim.api.nvim_buf_get_lines(bufnr, current_line - 1, current_line, false)[1]


    -- Check if the line contains your jq command
    if line_content and line_content:match('jq') then
        -- Extract the command from the line starting from 'jq'
        local cmd_start_col = line_content:find('jq') + 5
        -- If we are on the jq line and haven't already shown the float
        if jq.line ~= current_line then
            -- Close previous floating window if any
            if jq.vid and vim.api.nvim_win_is_valid(jq.vid) then
                vim.api.nvim_win_close(jq.vid, true)
                jq.vid = nil
                jq.bufnr = nil
            end

            -- Update jq.line
            jq.line = current_line

            -- Extract the command from the line (adjust as needed)
            local lines = M.get_jq_lines()
            local taskss = json.decode(lines)
            local tasks_str = {}

            if lines ~= nil then
                for _, task  in ipairs(taskss) do
                    table.insert(tasks_str,M.tostring(task))
                end
                -- Create a new buffer for the floating window
                jq.bufnr = vim.api.nvim_create_buf(false, true)  -- Create a scratch buffer

                -- Set buffer options
                vim.api.nvim_set_option_value('bufhidden', 'wipe', {buf = jq.bufnr, scope = "local"})

                -- Set the lines of the buffer to the output
                vim.api.nvim_buf_set_lines(jq.bufnr, 0, -1, false, tasks_str)

                -- Optionally set syntax highlighting if the output is JSON
                vim.api.nvim_set_option_value('filetype', 'markdown', {buf = jq.bufnr, scope = "local"})
                -- Calculate the maximum line length from the output
                local max_line_length = 0
                for _, line in ipairs(tasks_str) do
                    local line_length = vim.fn.strdisplaywidth(line)
                    if line_length > max_line_length then
                        max_line_length = line_length
                    end
                end

                -- Get the window width and height
                local width = vim.api.nvim_get_option("columns")
                local height = vim.api.nvim_get_option("lines")

                -- Calculate the width and height of the floating window
                local float_width = max_line_length + 2  -- Add padding
                local float_height = #taskss

                -- Ensure the floating window doesn't exceed the window boundaries
                if float_width > width - cmd_start_col then
                    float_width = width - cmd_start_col
                end
                if float_height > height - current_line - 2 then  -- Subtract 2 for padding
                    float_height = height - current_line - 2
                end

                -- Configure floating window options
                local opts = {
                    style = 'minimal',
                    relative = 'win',
                    width = float_width,
                    height = float_height,
                    row = current_line,
                    col = cmd_start_col - 1,  -- Adjust for 0-indexing
                    border = nil,
                    noautocmd = true,
                }

                -- Open the floating window
                jq.vid = vim.api.nvim_open_win(jq.bufnr, false, opts)

                -- Set window options to remove line numbers, signcolumn, etc.
                vim.api.nvim_set_option_value('number', false, { scope = "local", win = jq.vid })
                vim.api.nvim_set_option_value('relativenumber', false, { scope = "local", win = jq.vid })
                vim.api.nvim_set_option_value('signcolumn', 'no', { scope = "local", win = jq.vid })
                vim.api.nvim_set_option_value('foldcolumn', '0', { scope = "local", win = jq.vid })
                vim.api.nvim_set_option_value('cursorline', false, { scope = "local", win = jq.vid })
                vim.api.nvim_set_option_value('winhl', 'NormalFloat:Normal', { scope = "local", win = jq.vid })
            else
                -- Handle error (optional)
                print("Error executing command: " .. line_content)
            end
        end
    else
        -- If we move away from the jq line, close the floating window
        if jq.vid and vim.api.nvim_win_is_valid(jq.vid) then
            vim.api.nvim_win_close(jq.vid, true)
            jq.vid = nil
            jq.bufnr = nil
            jq.line = nil
        end
    end
end

function M.JqFix()
    if M.jq.vid then
        M.CloseJqFloat()
    end
    local cmd = M.get_cmd()
    if not cmd then
        return
    end
    local taskss, title = M.views.search(cmd)
    if not taskss then
        return
    end
    M.views.open_window(taskss, title)
end

function M.CloseJqFloat()
    if jq.vid and vim.api.nvim_win_is_valid(jq.vid) then
        vim.api.nvim_win_close(jq.vid, true)
        jq.vid = nil
        jq.bufnr = nil
        jq.line = nil
    end
end

-- Create the :JqFix command
vim.api.nvim_create_user_command('JqFix', M.JqFix, {})
-- Set up autocommands
vim.api.nvim_exec([[
  augroup JqFloatAutocmd
    autocmd!
    autocmd CursorMoved,CursorMovedI * lua require'dev.lua.tasks'.UpdateJqFloat()
    autocmd BufLeave,BufUnload,BufWinLeave * lua require'dev.lua.tasks'.CloseJqFloat()
  augroup END
]], false)

-- -- Set up autocommands
-- vim.api.nvim_exec([[
--   augroup JqResultAutocmd
--     autocmd!
--     autocmd CursorMoved,CursorMovedI * lua UpdateJqResult()
--     autocmd BufLeave,BufUnload,BufWinLeave * lua ClearJqResult()
--   augroup END
-- ]], false)

-- Map to a command
-- vim.api.nvim_create_user_command('Jq', M.UpdateJqResult, {})
-- vim.api.nvim_create_user_command('Jqc', M.ClearJqResult, {})

-- Or map to a keybinding (e.g., pressing <leader>jr runs the function)
vim.api.nvim_set_keymap('n', '<leader>jq', ':lua M.ShowJqResult()<CR>', { noremap = true, silent = true })

-- Add a command to run index function
vim.api.nvim_create_user_command('Index', 'lua require"dev.lua.tasks.indexer".index()',
    {
        nargs = 0,
        desc = 'Index note tasks  and save into json file'
    }
)

return M
