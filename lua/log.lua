require'time'
local gruvbox = require'gruvbox-term'

local Level = {
    TRACE = 1,
    DEBUG = 10,
    INFO = 20,
    WARN = 30,
    ERROR = 40,
    FATAL = 50,
}

Log = {
    log_level = Level.INFO,
    level = Level.INFO, -- module level
    module = nil,
    color = gruvbox.light0_hard,
    time_color = gruvbox.bright_purple,
    module_color = gruvbox.bright_yellow,
    -- dbg = require('debug'),
    fd = io.stdout,

    debug = function(self, msg)
        self:print(self:format(msg, "debug", gruvbox.bright_purple), Level.DEBUG)
    end,
    info = function(self, msg)
        self:print(self:format(msg, "info", gruvbox.bright_green), Level.INFO)
    end,
    warn = function(self, msg)
        self:print(self:format(msg, "warn", gruvbox.bright_yellow), Level.WARN)
    end,
    error = function(self, msg)
        self:print(self:format(msg, "error", gruvbox.bright_red), Level.ERROR)
    end,
    fatal = function(self, msg)
        self:print(self:format(msg, "fatal", gruvbox.bright_red), Level.FATAL)
    end,
    trace = function(self, msg)
        self:print(self:format(msg, "trace", gruvbox.bright_aqua), Level.TRACE)
    end,
    log = function(self, msg)
        self:print(self:format(msg,"trace", gruvbox.bright_aqua), Level.TRACE)
    end,
}

-- local mt_log = {
--     __index = function(t, k)
--         if k == "level" then
--             return t._level
--         elseif k == "_level" or k == "_log_level" then
--             return nil
--         elseif k == "log_level" then
--             return t._log_level
--         else
--             return rawget(t, k)
--         end
--     end,
--     __newindex = function(t, k, v)
--         if k == "level" then
--             if type(v) == "string" then
--                 t._level = Level2num(v)
--             else
--                 t._level = v
--             end
--             if k == "log_level" then
--                 if type(v) == "string" then
--                     t._log_level = Level2num(v)
--                 else
--                     t._log_level = v
--                 end
--             end
--         elseif k == "_level" or k == "_log_level" then
--         else
--             rawset(t, k, v)
--         end
--     end
-- }
-- setmetatable(Log, mt_log)


-- function Level2num(level)
--     if level == "debug" then
--         return Level.DEBUG
--     elseif level == "fatal" then
--         return Level.FATAL
--     elseif level == "error" then
--         return Level.ERROR
--     elseif level == "warn" then
--         return Level.WARN
--     elseif level == "trace" then
--         return Level.TRACE
--     elseif level == "info" then
--         return Level.INFO
--     else
--         return 0
--     end
-- end

-- format: [time] [level] [file:line] [message]
function Log:format (message, level, color)
    local reset = gruvbox.light0
    if not color then
        color = ''
        reset = ''
    end
    if not level then
        level = self.level
    end

    local log_date = string.format('[%s]', os.date('%Y/%m/%d %X'))
    local log_llevel = string.format('[%s]', level)
    local log_preffix = string.format("%s%s %s%-7s%s", self.time_color, log_date, color, log_llevel, reset)
    local log_module = ''
    if self.module then
        log_module = string.format('[%s]', self.module)
    end
    local log_mod = string.format(" %s%-10s%s", self.module_color, log_module, self.color)
    local log_suffix = string.format(" %s%s\n", message, gruvbox.reset)
    if self.module then
        return log_preffix .. log_mod .. log_suffix
        -- return string.format(log_preffix .. log_mod .. log_suffix
    else
        return log_preffix .. log_suffix
    end
    -- return string.format("[%s] [%s] [%s:%d] %s", self.time.now(), level, self.dbg.getinfo(2).short_src, self.dbg.getinfo(2).currentline, message)
end

function Log:print(msg,level)
    if level >= self.log_level then
        local fd = self.fd or io.stdout
        fd:write(msg)
    end
end

function Log:write(msg, level)
    if level >= self.log_level then
        io.write(msg)
    end
end
function Log.set_level(level)
    if level == 'debug' then
        Log.log_level = Level.DEBUG
    elseif level == 'info' then
        Log.log_level = Level.INFO
    elseif level == 'warn' then
        Log.log_level = Level.WARN
    elseif level == 'error' then
        Log.log_level = Level.ERROR
    elseif level == 'fatal' then
        Log.log_level = Level.FATAL
    end
end


Log.Level = Level

Log = require('class').class(Log, function(obj, module, filename)
    if module then
        obj.module = module
    end
    if filename then
        obj.filename = filename
        obj.fd = io.open(filename, "a")
    end
    return obj
end)
-- setmetatable(Log, mt)

return Log
