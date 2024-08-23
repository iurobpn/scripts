local uv = require('luv')

-- Create a timer that fires after 2 seconds
local timer1 = uv.new_timer()
timer1:start(2000, 0, function()
    print("Timer 1 fired after 2 seconds")
end)

-- Create a timer that fires after 1 second
local timer2 = uv.new_timer()
timer2:start(1000, 0, function()
    print("Timer 2 fired after 1 second")
end)

uv.run()
-- Long-running task to simulate blocking operation
local function long_running_task()
    print("Long running task started")
    uv.sleep(3000)  -- Sleep for 3 seconds (simulating a blocking task)
    print("Long running task finished")
end

-- Start the long-running task
long_running_task()

-- Start the event loop
