local Server = require'timer_server'

local host = '127.0.0.1'
local port = 12345
Log = require'log'
if #arg > 0 then
    argparse(arg[1])
    -- Log.set_level(arg[1])
end

local log = Log('launch_server');

-- Log.log_level = Log.Level.DEBUG
local server = Server(host,port,0,'server 1')
log:info('server process have started')
server:start(host,port,0)

log:info('server process have exited')
