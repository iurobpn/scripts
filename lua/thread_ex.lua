local apr = require("apr")
local llthreads = require("llthreads2.ex")

-- Function to run after timeout
local function on_timer()
    print("Time's up! Running callback function.")
end

-- Function to start the timer in a new thread
local function start_timer(timeout_sec, callback)
    local thread = llthreads.new(function(timeout)
        -- local socket = require("socket")
        require('apr').sleep(timeout)
        -- apr.sleep(timeout)
        -- socket.sleep(timeout)
        return true
    end, timeout_sec)

    thread:start()

    -- Thread join to get the result after the timer expires
    -- thread:join(0)

    -- Call the callback function after the timer finishes
    -- thread:set("on_timer", callback) -- Set the callback function to be called when thread finishes
    -- callback()
    return thread, callback
end


local thread, callback = start_timer(5, on_timer)
local i = 0
while i < 5 do
    print(i, ' s')
    apr.sleep(1)
    i = i + 1
    local finished, result = thread:join(0) -- Non-blocking check
    if finished then
        callback()
        break
    end
end

-- Usage example: Start a timer that runs the callback after 5 seconds
print('5 s done')
