local apr = require 'apr'
require 'class'
local Timer = {
    t_start = 0,
    t_lap = 0,
    t_stop = 0, -- timestamp value integer
    unit = "s", -- s, ms, us
    mode = "stopwatch" -- timer ("t"), stopwatch ("s")
}

local Duration = {
    dt = 0,
    unit = "s"
}

function Duration.to_unit(self, unit)
    if not unit then
        unit = "s"
    end
    local dt = self.dt
    if self.unit ~= "s" then
        dt = self:to_sec()
    end
    local out = Timer.to_unit(dt, unit)
    return out
end

function Duration.to_sec(self)
    local t = self.dt
    if self.unit == "ms" then
        t = t/1e3
    elseif self.unit == "us" then
        t = t/1e6
    end
    return t
end

-- t in seconds
function Duration.explode(self)
    local t = self:to_sec()
    hour = math.floor(t/3600)
    aux = t%3600
    min = math.floor(aux/60)
    aux = aux%60
    sec = math.floor(aux)
    aux = sec - aux
    msec = math.floor(aux*1e3)
    aux= aux * 1e3 - msec
    usec = math.floor(aux*1e3)
    return {hour = hour, min = min, sec = sec, msec = msec, usec = usec}
end


function Duration.to_string(self)
    local t = self:explode()
-- print all values in t
    -- af.v
    local s = ''
    local is_printing = false
    if t.hour > 0 then
        is_printing = true
        s = s .. string.format("%02d:", t.hour)
        print(string.format("hour: %02d:", t.hour))
    end
    if is_printing or t.min > 0 then
        is_printing = true
        s = s .. string.format("%02d:", t.min)
    end
    if is_printing or t.sec > 0 then
        if is_printing then
            s = s .. string.format("%02d h", t.sec)
        else
            s = s .. string.format("%ds", t.sec)
        end
    end
    if t.msec > 0 then
        s = s .. string.format(" %f ms", t.msec)
    elseif t.usec > 0 then
        s = s .. string.format(" %f us", t.usec)
    end
    return s
end

Duration = class(Duration, function(obj, type, tf, ti, unit)
    obj = obj or {}
    obj.unit = unit
    if ti and tf then
        obj.dt = tf - ti
    end
    obj.unit = unit
    return obj
end)


return Duration
