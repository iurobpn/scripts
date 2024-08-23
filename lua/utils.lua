-- Date: 2020/07/26
Log = require'log'
local inspect = require'inspect'
function print_table(...)
    for i,v in pairs({...}) do
        print(inspect(v))
    end
    -- print(inspect(t,{depth=3}))
end

function argparse(arg)
    if arg == 'help' then
        print('Usage: lua launch_tserver.lua [host] [port]')
        os.exit()
    end
    if arg == 'debug' then
        Log.log_level = Log.Level.DEBUG
        Log:info('log level set to DEBUG')
    end
    if arg == 'info' then
        Log.log_level = Log.Level.INFO
        Log:info('log level set to INFO')
    end
    if arg == 'warn' then
        Log.log_level = Log.Level.WARN
        Log:info('log level set to WARN')
    end
    if arg == 'error' then
        Log.log_level = Log.Level.ERROR
        Log:info('log level set to ERROR')
    end
    if arg[1] == 'fatal' then
        Log.log_level = Log.Level.FATAL
        Log:info('log level set to FATAL')
    end
end

function print_mt(t)
    local mt = getmetatable(t)
    print_table(mt)
end

function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end
