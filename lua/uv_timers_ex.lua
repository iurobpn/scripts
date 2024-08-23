
local uv = require('luv')

-- Create two timers
local timer1 = uv.new_timer()
local timer2 = uv.new_timer()

-- Timer 1 fires every 1000 milliseconds (1 second)
timer1:start(1000, 1000, function()
    print("Timer 1 tick")
end)

-- Timer 2 fires every 1500 milliseconds (1.5 seconds)
timer2:start(1500, 1500, function()
    print("Timer 2 tick")
end)

-- Stop the event loop after 5 seconds
uv.new_timer():start(5000, 0, function()
    print("Stopping event loop")
    uv.stop()
end)

-- Start the event loop
uv.run()
