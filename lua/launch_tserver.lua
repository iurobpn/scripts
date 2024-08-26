local insp = require('inspect')
-- script.lua
local argparse = require( "argparse")

local parser = argparse("launch_tserver", "launch Tserver")
-- parser:argument("input", "Input file.")
parser:option("-l --log-level", "Log Level.", "debug")
parser:option("-f --log-file", "Log file or tty.", "/dev/pts/1")

local args = parser:parse()
print(insp.inspect(args))

local host = '127.0.0.1'
local port = 12345
Log = require('dev.lua.log')

print('log_level ' .. args.log_level)
log_level = args.log_level
local log = Log('launch_server', '/dev/pts/1');
-- print('log.log_level>: ' ..log.log_level)
-- print(insp.inspect(Log))
-- print(insp.inspect(log))
print('log level ' .. log_level)
local Server = require('timer_server')
-- dofile('test.lua')

log:info('server process have starting')

local server = Server(host,port,0,'server 1','/dev/pts/1')
-- server.log.log_level = log_level
log:info('server process have started')
server:start(host,port,0)

log:info('server process have exited')
