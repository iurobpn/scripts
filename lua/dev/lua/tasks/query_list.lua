local utils = require'utils'

local M = {
    list = {
        {
            query = nil,
            description = nil,
        },
    },
}


function M.init()

    local list = {
        {
            query = '[ .[] | select(.id == %d) ]',
            description = 'select by id',
            inputs = { 'id' },
        },
        {
            query = '[ .[] | select(.status != "done" and .due != null and .tags[] == "%s") ]',
            description = 'select by tag with due date (undone)',
            inputs = { 'tag' },
        },
        {
            query = '[ .[] | select(.status != "done" and .tags[] == "%s") ]',
            description = 'select by tag (undone)',
            inputs = { 'tag' },
        },
    }
    local Msaved = vim.g.proj.get('query_list')
    if Msaved then
        M.list = Msaved
    else
        M.list = list
    end
    vim.g.proj.register('query_list', M.list)
end

function M.add(query)
    table.insert(M.list, query)
end

function M.remove(idx)
    table.remove(M.list, idx)
end

M.clean = function()
    for i = #M.list, 1, -1 do
        table.remove(M.list, i)
    end
end

function M.select()
    local list = {}
    for i, q in ipairs(M.list) do
        local desc = q.description:sub(1, 20)
        local query = string.format('%2d │ %-20s │ %s │ %s', i, desc, q.query, q.inputs)
        table.insert(list, query)
    end

    local selected = require('fzf-lua').fzf_exec(list, {
        prompt = 'Select a query>',
        actions = {
            ["default"] = function(selected)
                local sel = utils.split(selected[1], '│')
                local id = tonumber(sel[1])
                local query = M.list[id]
                local inputs = {}
                for _, input in ipairs(query.inputs) do
                    local input_val = vim.fn.input('Enter ' .. input .. ': ')
                    table.insert(inputs, input_val)
                end
                local q = string.format(query.query, table.unpack(inputs))
                local tasks = M.select(q)
                dev.lua.tasks.views.open_window(tasks, 'Custom query')
            end
        }
    })
end
M.save = function()
    vim.g.proj.save()
end

M.init()

return M
