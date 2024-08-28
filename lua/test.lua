require'class'
require'utils'

print('Log class: ')
local Log = require'dev.lua.log'
print('Log: ' .. require'inspect'.inspect(Log))
local log = Log('main')
print('Log mid: ' .. require'inspect'.inspect(Log))

local log2 = Log('log2')
print('Log final: ' .. require'inspect'.inspect(Log))
-- log.log_level = Log.Level.fatal
--
--
-- log:info('test log')
-- log:error('error log')
-- log:log('log log')
-- log:warn('warn log')
-- log:debug('debug log')
-- log:trace('trace log')
-- log:fatal('fatal log')

print('Foo class: ')
Foo = {}
Foo = class(Foo, {
    constructor = function(obj, ...)
        local argv = {...}
        argv = argv[1]
        obj.name = argv.name
        obj.age = argv.age
        return obj
    end,

    name = 'foo',
    age = 10
})
print('Foo: ' .. require'inspect'.inspect(Foo))
