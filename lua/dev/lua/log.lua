require'time'
local gruvbox = require'gruvbox-term'

local Level = {
    trace = 1,
    debug = 10,
    info = 20,
    warn = 30,
    error = 40,
    fatal = 50,
}

Log = {
    log_level = "info",
    level = "info", -- module level
    module = nil,
    color = gruvbox.light0_hard,
    time_color = gruvbox.bright_purple,
    module_color = gruvbox.bright_yellow,
    -- dbg = require('debug'),
    fd = io.stdout,
    colors = {
        trace = gruvbox.bright_aqua,
        debug = gruvbox.bright_purple,
        info = gruvbox.bright_green,
        warn = gruvbox.bright_yellow,
        error = gruvbox.bright_red,
        fatal = gruvbox.bright_red,
    },
}

function Log.write(self, msg, level)
    self:print(self:format(msg, level, self.colors[level]))
end

function Log:fatal(msg)
    self:write(msg, 'fatal')
end

function Log:error(msg)
    self:write( msg, 'error')
end

function Log:warn(msg)
    self:write(msg, 'warn')
end

function Log:info(msg)
    self:write(msg, 'info')
end

function Log:debug(msg)
    self:write(msg, 'debug')
end

function Log:trace(msg)
    self:write(msg, 'trace')
end

-- format: [time] [level] [file:line] [message]
function Log:format (message, level, color)
    local fmt = string.format
    local reset = gruvbox.light0
    if not color then
        color = ''
        reset = ''
    end
    if not level then
        level = self.level
    end

    local log_date = fmt('[%s]', os.date('%Y/%m/%d %X'))
    local log_llevel = fmt('[%s]', level)
    local log_preffix = fmt("%s%s%s %s%-7s%s", self.time_color, log_date, gruvbox.reset, color, log_llevel, gruvbox.reset)
    local log_module = ''
    if self.module then
        log_module = fmt('[%s]', self.module)
    end
    local log_mod = fmt(" %s%-10s%s%s", self.module_color, log_module, gruvbox.reset, self.color)
    local log_suffix = fmt(" %s%s", message, gruvbox.reset)
    if self.module then
        return log_preffix .. log_mod .. log_suffix
        -- return string.format(log_preffix .. log_mod .. log_suffix
    else
        return log_preffix .. log_suffix
    end
    -- return string.format("[%s] [%s] [%s:%d] %s", self.time.now(), level, self.dbg.getinfo(2).short_src, self.dbg.getinfo(2).currentline, message)
end

function Log:print(msg,level)
    level = level or self.level
    if Level[level] >= Level[self.log_level] then
         local fd = self.fd or io.stdout
        fd:write(msg)
    end
end

Log.Level = Level

Log = require('class').class(Log, function(obj, module, filename)
    if module then
        obj.module = module
    end
    if filename then
        obj.filename = filename
        obj.fd = io.open(filename, "w")
    end
    return obj
end)
-- setmetatable(Log, mt)

return Log
