require('dev.nvim.ui.qfloat')
require('dev.lua.sqlite2')
require('dev.lua.tasks.search')
local utils = require('utils')
local Tasks = require('dev.lua.tasks')

local tasks = Tasks()

-- local task1 = Tasks.select_by_id(238)
-- local task7 = Tasks.select_by_id(61)
print('pprint task1 and task7:')
-- pprint(task1)
-- pprint(task7)

local task_list = tasks.select_by_tag('#main')

local tasks_qf = {}
for id, task  in pairs(task_list) do
    table.insert(tasks_qf,{filename = task.filename, lnum = task.line_number, text = 'task_id: ' .. id .. '; ' .. task.description .. ' ' .. Tasks.params_to_string(task.parameters) .. ' ' .. Tasks.tags_to_string(task.tags)})
end


qset(tasks_qf)
qopen()


print('tasks_qf[1]:')
utils.pprint(tasks_qf[1])
