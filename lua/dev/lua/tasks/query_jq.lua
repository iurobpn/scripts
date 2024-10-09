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
    -- local query = fmt('jq "[ .[] | select(.id == %d)" %s ]', id, self:file())
    if type(id) == 'string' then
        id = tonumber(id)
    end
    if id == nil or id <= 0 then
        return nil
    end
    local query = '.id == ' .. id

    return query
end

function Query.select_by_tags(tags)
    local query
    -- if tag == nil then
    --     query = string.format([['[ .[] | select(.status != "done" and .due != null) ]']])
    -- else
    --     query = string.format([['[ .[] | select(.status != "done" and .due != null and .tags[] == "%s") ]']], tag)
    -- end
    query = '.tags[] == "' .. tags[1] .. '"'
    for i = 2, #tags do
        query = query .. ' or .tags[] == "' .. tags[i] .. '"'
    end
    return query
end

function Query.select_by_due(due)
    -- local query = string.format([['[ .[] | select(.status != "done" and .tags[] == "%s") ]' ]], tag)
    print('due', due)
    if due == nil then
        return nil
    end
    print('due after check', due)
    if due then
        return '.due != null'
    else
        return '.due == null'
    end
end

function Query.select_by_status(status)
    local query = nil
    if status == 'undone' then
        query = '.status != "done"'
    elseif status == 'done' then
        query = '.status == "done"'
    end

    return query
end

function Query:select(option)
    option = option or {}
    local query = '[ .[] | select('

    if option.id ~= nil then
        query = query .. self.select_by_id(option.id)
    end
    if option.status ~= nil then
        query = query .. self.select_by_status(option.status)
    end
    if option.due ~= nil then
        print('query:select due', option.due)
        query = query .. ' and ' .. self.select_by_due(option.due)
    end
    if option.tags ~= nil and #option.tags and option.tags[1] ~= nil then
        utils.pprint(option.tags, 'tags')
        query = query .. ' and ' .. self.select_by_tags(option.tags)
    end
    query = query .. ')]'
    -- '.status != "done" and .due != null) ]']])

    local cmd = string.format("jq '%s' %s", query, self:file())
    local str_tasks = utils.get_command_output(cmd)
    local tasks
    if str_tasks == '' then
        tasks = {}
    else
        tasks = vim.fn.json_decode(str_tasks)
    end

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
