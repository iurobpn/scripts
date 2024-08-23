
local Timer = require('par_timer')  -- Assume the above code is saved in 'timer.lua'

local uv = require('luv')

-- Create a Timer object and start its thread
local timer = Timer({})
local thread, pipe_main_to_timer = timer:start_timer_thread()

-- Define a callback function
local function callback()
    print("Timer callback executed")
end

-- Start a new timer for 3000ms (3 seconds)
timer:send(pipe_main_to_timer, "new_timer", nil, 3000, callback)

-- After 1000ms, send a pause command
uv.sleep(1000)
timer:send(pipe_main_to_timer, "pause")

-- After another 2000ms, resume the timer
uv.sleep(2000)
timer:send(pipe_main_to_timer, "resume")

-- After 5000ms, stop all timers and terminate the program
uv.sleep(5000)
timer:send(pipe_main_to_timer, "stop_all")

-- Wait for the timer thread to finish
uv.thread_join(thread)
