local qfloat = require('dev.nvim.ui.qfloat')
local utils = require('utils')
local Tasks = require('dev.lua.tasks')

local query = Tasks.query.Query()

-- local task1 = Tasks.select_by_id(238)
-- local task7 = Tasks.select_by_id(61)
print('pprint task1 and task7:')

local tasks = query:select_by_tag('#main')

local tasks_qf = {}
for id, task  in pairs(tasks) do
    table.insert(tasks_qf, {filename = task.filename, lnum = task.line_number, text = 'task_id: ' .. id .. '; ' .. task.description .. ' ' .. Tasks.query.Query.params_to_string(task.parameters) .. ' ' .. Tasks.query.Query.tags_to_string(task.tags)})
end

utils.pprint(tasks_qf,'tasks_qf')
qfloat.qset(tasks_qf)
qfloat.qopen()

print('tasks_qf[1]:')
utils.pprint(tasks_qf[1])

