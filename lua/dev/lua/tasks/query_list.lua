local utils = require'utils'
local prj = require 'dev.lua.project'
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
        },
        {
            query = '[ .[] | select(.status != "done" and .due != null and .tags[] == "%s") ]',
            description = 'select by tag with due date (undone)',
        },
        {
            query = '[ .[] | select(.status != "done" and .tags[] == "%s") ]',
            description = 'select by tag (undone)',
        },
    }
    local Msaved = prj.get('query_list')
    if Msaved then
        M.list = Msaved
    else
        M.list = list
    end
    prj.register('query_list', M.list)
end

function M.add(query)
    table.insert(M.list, query)
end

function M.remove(idx)
    table.remove(M.list, idx)
end

function M.select()
    local list = {}
    for i, q in ipairs(M.list) do
        table.insert(list, tostring(i) .. '| ' .. q.description .. '|' .. q.query)
    end
    local selected = require('fzf-lua').fzf_exec(list, {
        prompt = 'Select a query>',
        actions = {
            ["default"] = function(selected)
                local sel = utils.split(selected[1], '|')
                local q = sel[3]
                local tasks = M.select(q)
                dev.lua.tasks.views.open_window(tasks, 'Custom query')
            end
        }
    })
end
M.init()
return M
