local json = require('dkjson')
require('dev.lua.utils')
require('dev.lua.sqlite2')
require('dev.lua.tasks.search')

local task1 = select_by_id(238)
local task7 = select_by_id(61)
print('pprint task1 and task7:')
pprint(task1)
pprint(task7)

local tasks = select_by_tag('#main')
