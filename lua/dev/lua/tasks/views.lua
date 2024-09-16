local fzf_lua = require('fzf-lua')
local fzf = require('dev.nvim.fzf')
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

function M.format_tasks(tasks)
    local tasks_qf = {}
    for id, task  in pairs(tasks) do
        if task.line_number == nil then
            error('task.line_number is nil')
        end
        table.insert(tasks_qf, {filename = task.filename, lnum = task.line_number, text = (task.description or '') .. ' ' .. M.params_to_string(task.parameters) .. ' ' .. M.tags_to_string(task.tags)})
    end

    return tasks_qf
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

function M.fzf_query(tag)
    local tasks = M.query_by_tag(tag)
    local str_tasks = M.to_lines(tasks)
    print('number of tasks: ' ..utils.numel(str_tasks))

    -- Inherit from the "buffer_or_file" previewer
    local fd = io.open('fzf.log', 'w')
    for _, task in ipairs(str_tasks) do
        fd:write(task .. '\n')
    end
    fd:close()

    fzf_lua.fzf_exec(str_tasks, {
        previewer = pv.Previewer,
        prompt    = 'Tasks❯ ',
        cwd       = query.Query.path,

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

-- create_command
vim.api.nvim_create_user_command('TaskFzf', M.fzf_query, {
    nargs = 1,
    complete = 'customlist,v:lua.dev.nvim.tasks.complete_tag',
})
vim.api.nvim_set_keymap('n', '<F11>', ':TaskFzf ', {noremap = true, silent = true})

function M.open_window_by_tag(tag)
    local tasks_qf = M.query_by_tag(tag)
    float.qset(tasks_qf)
    float.qopen()
end

return M
