local prj = require 'dev.lua.project'
local Query = require 'dev.lua.tasks.query'.Query
local M = {
    list = {
        {
            query = nil,
            description = nil,
        },
    },
    picker = Query()
}


function M.init()
    local Msaved = prj.get('query_list')
    if Msaved then
        M.list = Msaved
    end
    prj.register('query_list', M.list)
end

function M.add(query)
    table.insert(M.list, query)
end

function M.select()
    local query_names = {}
    for i, query in ipairs(M.list) do
        table.insert(query_names, tostring(i) .. ': ' .. query.name)
    end
    local selected = require('fzf-lua').fzf_exec(query_names, {
        prompt = 'Select a query>',
        actions = {
            ["default"] = function(selected)
                local sel = utils.split(selected[1], ':')
                local query = sel[2]
                M.picker.select_tasks(query)
            end
        }
    })
end



