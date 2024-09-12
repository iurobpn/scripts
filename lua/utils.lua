-- Date: 2020/07/26
Log = require'dev.lua.log'
local insp = require'inspect'
local fmt = string.format

local M = {}
function M.file_exist(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end


function M.is_callable(f)
    local fmt = getmetatable(f)
    return type(f) == 'function' or (fmt ~= nil and fmt.__call ~= nil)
end

function M.print_table(...)
    for k,v in pairs({...}) do
        print('key: ' .. k .. ': ' .. insp.inspect(v))
    end
    -- print(inspect(t,{depth=3}))
end

function M.pprint(obj,s)
    print(fmt('%s%s', s or '', insp.inspect(obj, {depth=3})))
end

function M.numel(t)
    local n = 0
    for _,_ in pairs(t) do
        n = n + 1
    end
    return n
end

function M.argparse(arg)
    if arg == 'help' then
        print('Usage: lua launch_tserver.lua [host] [port]')
        os.exit()
    end
    if arg == 'debug' then
        Log.log_level = Log.Level.debug
        Log:info('log level set to DEBUG')
    end
    if arg == 'info' then
        Log.log_level = Log.Level.info
        Log:info('log level set to INFO')
    end
    if arg == 'warn' then
        Log.log_level = Log.Level.warn
        Log:info('log level set to WARN')
    end
    if arg == 'error' then
        Log.log_level = Log.Level.error
        Log:info('log level set to ERROR')
    end
    if arg[1] == 'fatal' then
        Log.log_level = Log.Level.fatal
        Log:info('log level set to FATAL')
    end
end

function M.print_mt(t)
    local mt = getmetatable(t)
    M.print_table(mt)
end

function M.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end

    return t
end

function M.get_command_output(cmd)
    -- Execute the Fish shell command and capture the output
    local handle = io.popen(cmd)
    if not handle then
        print("Failed to execute command: " .. cmd)
        return nil
    end
    local result = handle:read("*a")
    handle:close()

    -- Return the output, trimming any trailing newlines
    return result --:gsub("%s+$", "")
end

function M.traceback()
    local level = 1
    while true do
        local info = debug.getinfo(level, "Sl")
        if not info then break end
        if info.what == "C" then   -- is a C function?
            print(level, "C function")
        else   -- a Lua function
            print(string.format("%s:%d",
                info.short_src, info.currentline))
        end
        level = level + 1
    end
end

-- convert backtrace to quickfix list
function M.qbacktrace ()
    require'debug'
    local bt = debug.traceback()
    local f = '/tmp/bt.log'
    local file = io.open(f, 'w')
    file:write(bt)
    file:close()
    vim.cmd.cfile(f)
end

function M.ppprint(tbl, indent)
    print(M.insp(tbl))

    -- indent = indent or 0
    -- local indent_str = string.rep("  ", indent)
    --
    -- if type(tbl) ~= "table" then
    --     print(indent_str .. tostring(tbl))
    --     return
    -- end
    --
    -- print(indent_str .. "{")
    -- indent_str = string.rep("  ", indent)
    -- for k, v in pairs(tbl) do
    --     local key
    --     if type(k) == "string" then
    --         key = k -- No brackets for string keys
    --     else
    --         key = "[" .. tostring(k) .. "]" -- Use brackets for non-string keys
    --     end
    --     
    --     io.write(indent_str .. "  " .. tostring(key) .. " = ")
    --     
    --     if type(v) == "table" then
    --         M.pprint(v, indent + 4)
    --     else
    --         print(tostring(v) .. ",")
    --     end
    -- end
    -- print(indent_str .. "}")
end


return M
