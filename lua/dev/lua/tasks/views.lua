local fzf_lua = require('fzf-lua')
local nvim = {
    utils = require('dev.nvim.utils')
}

local float = require('dev.nvim.ui.float')
local query = require('dev.lua.tasks.query')
local utils = require('utils')
local pv = require('dev.nvim.ui.fzf_previewer')

require('class')

local M = {

}

-- M = class(M, {constructor = function(self, filename)
--     if filename ~= nil then
--         self.filename = filename
--     end
--     self.sql = sql.Sql(self.path .. self.filename)
--     return self
-- end})

function M.params_to_string(parameters)
    local str = ''
    if parameters == nil then
        return str
    end
    for k,v in pairs(parameters) do
        str = str .. '[' .. k .. ':: ' .. v .. '] '
    end
    return str
end

function M.tags_to_string(tags)
    local str = ''
    if tags == nil then
        return str
    end
    for _,tag in ipairs(tags) do
        str = str ..  tag .. ' '
    end
    return str
end

function M.open_context_window(filename, line_nr)
    local context_width = math.floor(vim.o.columns * 0.4)
    local context_height = math.floor(vim.o.lines * 0.5)
    local context_row = math.floor((vim.o.lines - context_height) / 4)
    local context_col = math.floor(vim.o.columns * 0.55)

    local content = nvim.utils.get_context(filename, line_nr)

    local win = nvim.ui.views.fit()
    win:config(
        {
            -- relative = 'editor',
            -- size = {
            --     absolute = {
            --         width = context_width,
            --         height = context_height,
            --     },
            -- },

            position = {
                absolute = {
                    row = context_row,
                    col = context_col,
                },
            },
            buffer = nvim.ui.views.get_scratch_opt(),
            border = 'single',
            modifiable = false,
            content = content,
            options = {
                winbar = 'file context on line ' .. line_nr,
            },
        }
    )

    win:open()
    -- vim.cmd('set ft=markdown')
    --get last line nr
    line_nr = math.floor(#content/2)
    vim.api.nvim_win_set_cursor(win.vid, {line_nr, 0})
end

function M.tostring(tasks)
    local tasks_qf = M.format_tasks(tasks)
    local out = ''
    for _, task in pairs(tasks_qf) do
        out = out .. string.format('%s:%d: %s\n', task.filename, task.lnum, task.text)
    end

    return out
end

function M.set_custom_hl(buf, line)

    local entry = vim.api.nvim_buf_get_lines(buf, line-1, line, false)
    
    entry = entry[1]
    if entry == nil then
        print(string.format('could not get line %d from buffer', line))
        return
    end
    local due_date = entry:match("due:: (%d%d%d%d%-%d%d%-%d%d)")
    if due_date == nil then
        print('no due date found')
        return
    end
    vim.api.nvim_set_hl(0, 'MetaTags', { fg = "#818181", italic = true })  -- Adjust the color as needed
    -- Define the namespace for extmarks (you can use the same namespace for multiple extmarks)
    local ns_id = vim.api.nvim_create_namespace('previewer_due')
    -- Create your custom highlight group with color similar to comments

    -- Set virtual text at a given line (line 2 in this case, 0-based index)
    vim.api.nvim_buf_set_extmark(buf, ns_id, line-1, 0, {
        virt_text = { { string.format("(due: %s) ", due_date), "MetaTags" } },  -- Text and optional highlight group
        virt_text_pos = "inline",
        -- virt_text_pos = "eol",  -- Places the virtual text at the end of the line
    })
end

function M.to_lines(tasks)
    local tasks_qf = M.format_tasks(tasks)
    local out = {}
    local path = query.Query.path
    for _, task in pairs(tasks_qf) do
        -- local file = task.filename:sub(path:len()+1, task.filename:len())
        -- if file[1] == '/' then
        --     file = file.sub(2, file:len())
        -- end
        table.insert(out, string.format('%s:%d:', task.filename, task.lnum))
    end
    vim.cmd('lcd ' .. query.Query.path)

    return out
end

function M.format_file_line(tasks)
    if tasks == nil then
        error('tasks is nil')
    end
    local out = {}
    for id, task  in pairs(tasks) do
        if task.line_number == nil then
            error('task.line_number is nil')
        end
        table.insert(out,string.format('%s:%d:', task.filename, task.line_number))
    end

    return out
end

function M.format_tasks_short(tasks)
    local tasks_qf = {}
    for id, task  in pairs(tasks) do
        if task.line_number == nil then
            error('task.line_number is nil')
        end
        table.insert(tasks_qf, {filename = task.filename, lnum = task.line_number, text = (task.description or '') .. ' ' .. M.params_to_string(task.parameters) .. ' ' .. M.tags_to_string(task.tags)})
    end

    return tasks_qf
end

function M.format_tasks(tasks_in)
    local tasks = {}
    local files = {}
    for id, task  in pairs(tasks_in) do
        if task.line_number == nil then
            error('task.line_number is nil')
        end
        table.insert(tasks, '- [ ] ' .. (task.description or '') .. ' ' .. M.params_to_string(task.parameters) .. ' ' .. M.tags_to_string(task.tags))
        table.insert(files, {task.filename, task.line_number})
    end

    return tasks, files
end


function M.query_by_tag_and_due(tag)
    local q = query.Query()
    local tasks = q:select_by_tag_and_due(tag)

    return tasks
end
function M.query_by_tag(tag)
    local q = query.Query()
    local tasks = q:select_by_tag(tag)

    return tasks
end

function M.parse_entry(entry_str)
    -- Assume an arbitrary entry in the format of 'file:line'
    local task_splited = utils.split(entry_str, ':')
    if task_splited == nil then
        error('task_splited is nil')
    end
    local path = task_splited[1]
    local line = task_splited[2]
    return {
        path = string.format('"%s"', path),
        line = tonumber(line) or 1,
        col = 1,
    }
end

function M.fzf_query_due(tag, ...)
    local opts = {...}
    opts = opts[1] or {}

    if opts.due == nil then
        opts.due = {order = 'ASC'}
    end
    M.fzf_query(tag, opts)
end

function M.fzf_query(tag, ...)
    local opts = {...}
    opts = opts[1] or {}
    local tasks
    if opts == nil or opts.due == nil then
        tasks = M.query_by_tag(tag)
    else
        local order = nil
        if opts.due ~= nil and opts.due.order ~= nil then
            order = opts.due.order
        end
        tasks = M.query_by_tag_and_due(tag, order)
    end
    local str_tasks = M.to_lines(tasks)

    -- debug
    local fd = io.open('fzf.log', 'w')
    if not fd then
        error('Cannot open fzf.log')
    end
    for _, task in ipairs(str_tasks) do
        fd:write(task .. '\n')
    end
    fd:close()

    fzf_lua.fzf_exec(str_tasks, {
        previewer = pv.Previewer,
        prompt    = 'Tasks❯ ',
        cwd       = query.Query.path,
        fzf_opts = {
            ["--no-sort"] = true,
        },

        -- actions inherit from 'actions.files' and merge
        actions = {
            ["default"] = function(selected)
                if selected then
                    for _, task in ipairs(selected) do
                        local filename, line_nr = utils.get_file_line(task, ':')
                        if filename and line_nr then
                            vim.cmd.edit(filename)
                            vim.fn.cursor(line_nr, 1)
                        end
                    end
                end
            end
        },
    })
    -- require'fzf-lua'.files(str_tasks, task_query_opts)
end

function M.open_due_window(tag)
    
    local tasks_tb = M.query_by_tag_and_due(tag)
    local tasks_line, files = M.format_tasks(tasks_tb)
    local win = dev.nvim.ui.views.scratch(tasks_line, {
        title = (tag or '') .. ' tasks',
        title_pos = 'center'})
    vim.cmd("set ft=markdown")
    vim.cmd("TSContextDisable")
    vim.api.nvim_win_set_option(0, 'winhighlight', 'Normal:Normal')

    local buffer = vim.api.nvim_win_get_buf(win.vid)
    for i, file in ipairs(files) do
        M.set_custom_hl(buffer, i)
    end
    -- win.buffer
end

-- create_command
vim.api.nvim_create_user_command('TaskOpenTagDue', 'lua dev.lua.tasks.views.open_due_window(<args>)', {
    nargs = 1,
})
vim.api.nvim_create_user_command('TaskTagDue', 'lua dev.lua.tasks.views.fzf_query_due(<args>)', {
    nargs = 1,
})
vim.api.nvim_create_user_command('TaskTagSearch', 'lua dev.lua.tasks.views.fzf_query(<args>)', {
    nargs = 1,
})
vim.api.nvim_set_keymap('n', '<F11>', ':TaskTagSearch ', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<F9>', ':TaskTagDue ', {noremap = true, silent = true})

function M.open_window_by_tag(tag)
    local tasks_qf = M.query_by_tag(tag)
    float.qset(tasks_qf)
    float.qopen()
end

return M
