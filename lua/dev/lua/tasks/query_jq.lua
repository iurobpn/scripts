local utils = require('utils')
require('class')
local M = {
    list = require('dev.lua.tasks.query_list'),
}

local Query = {
    filename = 'tasks.json',
    mod_dir = '.tasks',
    path = '/home/gagarin/sync/obsidian',
}


Query = class(Query, {constructor = function(self, filename)
    if filename ~= nil then
        self.filename = filename
    end
    return self
end})

Query.file = function(self)
    return self.path .. '/' .. self.mod_dir .. '/' .. self.filename
end

function Query.params_to_string(parameters)
    local str = ''
    for k,v in pairs(parameters) do
        str = str .. '[' .. k .. ':: ' .. v .. '] '
    end
    return str
end

function Query.tags_to_string(tags)
    local str = ''
    for _,tag in ipairs(tags) do
        str = str ..  tag .. ' '
    end
    return str
end

function Query:select_by_id(id)
    local fmt = string.format
    id = id or 1
    local query = fmt('jq "[ .[] | select(.id == %d)" %s ]', id, self:file())

    return self:select(query)
end

function Query:select_by_tag_and_due(tag, order)
    local query
    if tag == nil then
        query = string.format([['[ .[] | select(.status != "done" and .due != null) ]']])
    else
        query = string.format([['[ .[] | select(.status != "done" and .due != null and .tags[] == "%s") ]']], tag)
    end
    return self:select_tasks(query)
end

function Query:select_by_tag(tag)
    -- local query_tag = "select distinct t.id from tasks t left join tags tg ON t.id = tg.task_id where tg.tag = '#main'"
    -- local query_task = fmt('SELECT * FROM tasks WHERE id = %s;', tag)
    -- local query_tags = fmt('SELECT tag FROM tags WHERE task_id = %s;', tag)
 --    local query_params = fmt('SELECT name, value FROM parameters WHERE task_id = %d;', tag)
    local query = string.format([['[ .[] | select(.status != "done" and .tags[] == "%s") ]' ]], tag)

    return self:select(query)
end

function Query:select(query)

    local cmd = string.format('jq %s %s', query, self:file())
    local str_tasks = utils.get_command_output(cmd)
    local tasks = vim.fn.json_decode(str_tasks) 

    return tasks
end

function Query.open_context_window(filename, line_nr)
    
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
            content = content,
            options = {
                buffer = {
                    modifiable = false,
                },
                window = {
                    wrap = false,
                    winbar = 'file context on line ' .. line_nr,
                },
            },
        }
    )

    win:open()
    -- vim.cmd('set ft=markdown')
    --get last line nr
    line_nr = math.floor(#content/2)
    vim.api.nvim_win_set_cursor(win.vid, {line_nr, 0})
end
M.Query = Query

return M
