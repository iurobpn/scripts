require 'time'
local Timer = require 'timer'.Timer
local uv = require 'luv'
Log = require 'log'
-- Log.log_level = Log.Level.debug
local log = Log("ex_timer")

local ip = "127.0.0.1"
local port1 = 12345
local port2 = 12346
log:info("start module")
local t = Timer(ip, port1, "timer 1")
-- t.log.log_level = Log.Level.debug

-- t.mode = "timer"
-- print("\n\ntimer in mode " .. t.mode)
local ts1 = t:start(5)
log:info("ts1: " .. ts1)

-- local t2 = Timer(ip, port2, "timer 2")
-- t2.mode = "stopwatch"
-- print("timer in mode " .. t2.mode)
-- t2:reset()
-- local ts = t2:start()
-- uv.run('nowait')
clock.sleep(1)
print("\n")
-- log:log("ts2: " ..ts)
-- local tf = t2:stop()
-- print("t2.tf: " .. tf .. " " .. t2.unit)
-- t:join()
-- t2:join()
-- t2:print()
-- tf = t:stop()
local tf, err = t:stop()
if tf then
    log:info("t.tf: " .. tf .. " " .. t.unit)
else
    log:error("error, timer did not returned a valid elapsed time: %s",tf)
end
clock.sleep(0.1)
-- tf = t2:stop()
-- print("t2.tf: " .. tf .. " " .. t2.unit)
-- t:join()
-- t2:join()
-- timer.test()
-- time.sleep(5)
log:info("end module")
-- while true do
--    uv.run('nowait')
-- end

