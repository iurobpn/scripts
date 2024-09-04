require'utils'
local parser = require'dev.lua.tasks.parser'


local task = "- [ ] [[Master's Paper]] Write the introduction [id:: 1] #paper #writing"
local task2 = "- [ x ] [[Master's Paper]] Write the introduction #paper [id:: 1] #writing"
local description = task:match('%-%s*%[%s*[a-z ]%s*%]%s*(.*)')
local description2 = task2:match('%-%s*%[%s*[a-z ]%s*%]%s*(.*)')
print(description)
print(description2)


local new_task = parser.parse(task)
print_table(new_task)
new_task = parser.parse(task2)
print_table(new_task)
