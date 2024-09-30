local lg = require'dev.lua.log'

-- log = Log('logger','/dev/pts/1' )
local log = lg.Log('logger')
lg.Log.log_level = "debug"
log:fatal('fatal\n')
log:info('info\n')
log:warn('warn\n')
log:error('error\n')
log:debug('debug\n')
log:trace('trace\n')
