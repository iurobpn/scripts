local temp = require('dev.lua.templater')

local template = [[
Today is {{Today}}
Reminders
{{&reminders}}
    ]]

local s = temp.templater:render(template, temp.templates) 
print('Result:\n' .. s)
