local json = require('dkjson')
require('dev.lua.utils')
require('dev.lua.sqlite2')


local task1 = select_task(1)
local task7 = select_task(7)
print('pprint task1 and task7:')
pprint(task1)
pprint(task7)

