local fzf = require('dev.nvim.fzf')
local nvim = {
    utils = require('dev.nvim.utils')
}
local float = require('dev.nvim.ui.float')
local query = require('dev.lua.tasks.query')
local utils = require('utils')

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

    print('filename: ' .. filename)
    print('line_nr: ' .. line_nr)
    local content = nvim.utils.get_context(filename, line_nr)
    print('content: (open_context_window)')

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
        utils.pprint(task)
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
        table.insert(out, string.format('%s:%d: %s', task.filename, task.lnum, task.text))
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
        print('task(format_tasks):')
        utils.pprint(task)
        if task.line_number == nil then
            error('task.line_number is nil')
        end
        table.insert(tasks_qf, {filename = task.filename, lnum = task.line_number, text = 'task_id ' .. id .. '; ' .. (task.description or '') .. ' ' .. M.params_to_string(task.parameters) .. ' ' .. M.tags_to_string(task.tags)})
    end

    return tasks_qf
end

function M.query_by_tag(tag)
    local q = query.Query()
    local tasks = q:select_by_tag(tag)

    return tasks
end

function M.fzf_query(tag)
    local tasks = M.query_by_tag(tag)
    local str_tasks = M.to_lines(tasks)
    utils.pprint(str_tasks)

    fzf.exec(str_tasks, {
        cwd = query.Query.path,
        prompt = 'Search Tasks> ',
        multi = true,  -- Allow multiple selections
        fzf_opts = {
            ["--delimiter"] = ':',
            ["--with-nth"] = 1,
            ["--nth"] = 1,
            ["--preview-window"] = "right:60%",
        },

            previewer = 'builtin',
        -- previewers = {
        --     -- Enable syntax highlighting for the preview window.
        --     bat = {
        --         cwd = query.Query.path,
        --         enabled = true,
        --         theme = 'gruvbox-dark',  -- Choose your preferred theme
        --         args = '--style=header,grid --color always --line-range :500 "{1}"',
        --     }
        -- },
        sink = function(selected)
            if selected then
                for _, task in ipairs(selected) do
                    local task_splited = utils.split(task, ':')
                    if task_splited == nil then
                        error('task_splited is nil')
                    end
                    local filename = task_splited[1]
                    local line_nr = task_splited[2]
                    if filename and line_nr then
                        vim.cmd.edit(filename)
                        vim.fn.cursor(tonumber(line_nr), 1)
                    end
                end
            end
        end
    })
            --    sink = function(selected)
            --     -- capture the selected tasks
            --     local selected_tasks = {}
            --     for _, task_line in ipairs(selected) do
            --         -- extract file and line information (and other data)
            --         table.insert(selected_tasks, task_line)
            --     end
            --
            --     -- prompt for refining the search on the selected tasks
            --     m.prompt_refine_search(selected_tasks)
            -- end
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
