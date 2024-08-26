require'utils'
local Log = require'log'

local log = Log('main')

log.log_level = Log.Level.fatal


log:info('test log')
log:error('error log')
log:log('log log')
log:warn('warn log')
log:debug('debug log')
log:trace('trace log')
log:fatal('fatal log')

