local apr = require 'apr'
local Duration = require 'duration'
local timer = {};
local Timer = {
    t_start = 0,
    t_lap = 0,
    t_stop = 0, -- timestamp value integer
    unit = "s", -- s, ms, us
    mode = "stopwatch" -- timer ("t"), stopwatch ("s")
}
Timer.__index = Timer

Duration = {
    dt = 0,
    unit = "s"
}
Duration.__index = Duration

function Duration.new(tf, ti, unit)
    local obj = {}
    local self = setmetatable(obj, Duration)
    if ti and tf then
        self.dt = tf - ti
    end
    if unit then
        self.unit = unit
    end
    return  self
end

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

function Timer.now()
    return apr.time_now()
end

function Timer.tnow()
    return apr.time_explode(Timer.now())
end

function Timer.write_time(self,time)
    local t = time;
    if (time == nil) then
        t = self.tnow();
    end
    Timer.write(string.format("%02d:%02d:%02d", t.hour, t.min, t.sec))
end

function Timer.write(text)
    if vim then
        local n_line= vim.fn.line('.')
        local n_col = vim.fn.col('.')
        local line = vim.fn.getline(n_line)
        local prefix = string.sub(line, 1, n_col)
        local suffix = string.sub(line, n_col+1)
        local new_line = prefix .. text .. suffix
        vim.fn.setline(n_line, new_line)
    end
end

function Timer.start(self, t_end)
    self.t_start = Timer.now()
    if self.mode == "timer" then
        print("timer mode\n")
        local co = coroutine.wrap(function()
            local t_now = Timer.now()
            print("ti: " .. 0 .. "s\n")
            local t_int = 0
            print("t_now-t_start: " .. t_now - self.t_start .. "s\n")
            while t_now - self.t_start < t_end do
                coroutine.yield()
                t_now = Timer.tnow()
                local t_int_new = math.floor(t_now - self.t_start)
                if t_int ~= t_int_new then
                    t_int = t_int_new
                    print("ti: " .. t_int .. "s\n")
                end
            end
        end)
        co()
    else
        print("stopwatch mode\n")
        self.t_lap = self.t_start
    end
    return self.t_start
end

function Timer.stop(self)
    print("\nstop()\n")
    self.t_stop = self.now()
    print("t_stop-t_start: " .. self.t_stop - self.t_start .. "s\n")
    print("t_start: " .. self.t_start .. "s\n")
    print("t_stop: " .. self.t_stop .. "s\n")
    print("t_lap: " .. self.t_lap .. "s\n")
    local dt = self:get_duration(self.t_stop, self.t_start, self.unit)
    print("\nduration obj\n")
    table.foreach(dt, print)
    print("\n" .. type(dt).. "\n")
    local ot =dt:to_unit()
    return ot 
end

function Timer.reset(self)
    self.t_start = 0
    self.t_lap = 0
    self.t_stop = 0
end

function Timer.duration(self)
    return self:get_duration(self.now(), self.t_start,self.unit):to_unit()
end

function Timer.lap_duration(self)
    local out =  self:get_duration(self.now(), self.t_lap, self.unit)
    return out:to_unit()
end

function Timer.get_duration(self, t2, t1, unit)
    unit = unit or self.unit
    local dt = Duration(t2, t1, unit)
    print(dt)
    table.foreach(dt, print)
    return dt
end

function Timer.lap(self)
    local t_now = self.now()
    local dt = self:get_duration(t_now, self.t_lap, self.unit)
    self.t_lap = t_now
    return dt:to_unit()
end

function Timer.to_unit(t, unit)
    print("Timer.to_unit()\n")
    unit = unit or "s"
    print("\nto_unit()\nt: " .. t .. " unit: " .. unit .. "\n")
    if type(t) == "table" and t.dt  then
        unit = t.unit
        t = t.dt
    end
    -- TODO convert t to seconds and then to unit
    -- to unit must consider several conversions, see if there is a easier way or a library to do this


    t = Timer.to_unit(t,unit)
    print("t: " .. t .. " unit: " .. unit .. "\n")

    return t
end

function Timer.print(self,t)
    if t == nil then
        t = self:get_duration(self.t_stop, self.t_start)
    end
    print(self:to_string(t))
end

-- function to convert from time in seconds to a string in the format HH:MM:SS:MS:US
-- @param t time in seconds
-- @return string in the format HH:MM:SS:MS:US
-- @usage Timer.to_string(1.5) -> "00:00:01:500:000"
-- @usage Timer.to_string(1.5, "ms") -> "00:00:01:500"
-- @usage Timer.to_string(1.5, "us") -> "00:00:01:500000"
-- @usage Timer.to_string(1.5, "s") -> "00:00:01"
-- @usage Timer.to_string(1.5, "m") -> "00:01"
--

function Timer.explode(t)
    local hour = math.floor(t/3600)
    local aux = t%3600
    local min = math.floor(aux/60)
    aux = aux%60
    local sec = math.floor(aux)
    aux = sec - aux
    local msec = math.floor(aux*1e3)
    aux= aux * 1e3 - msec
    local usec = math.floor(aux*1e3)
    return {hour = hour, min = min, sec = sec, usec = usec}
end

function Timer.to_string(self, t, unit)
    if t == nil or t.dt ~= nil then
        t = self:get_duration(self.t_stop, self.t_start)
        return t:to_string()
    end
    if t and type(t) ~= "table" then
        t = Timer.explode(t)
    end
    if t.msec == nil then
        t.msec = t.usec/1e3
        t.usec = t.usec%1e3
    end
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

function Timer.to_us(t)
    return t*1e6
end
--always assume seconds as t unit
function Timer.to_ms(t)
    return t * 1e3;
end
function Timer.to_sec(t)
    return t
end

--[[
let save_a_mark = getpos("'a")
" ...
call setpos("'a", save_a_mark)
--]]
--
--
--os.difftime

timer.Timer = require('class').class(Timer)

function timer.test()
    local t = Timer()
    t:start()
    apr.sleep(1)
    local tf = t:stop()
    print("tf: " .. tf .. " " .. t.unit)
    t:print()

end
timer.Duration = Duration

return timer
