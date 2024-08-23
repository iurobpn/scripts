
local uv = require('luv')

-- Function to be executed in the worker thread
local function timer_thread(pipe_read)
    local running = true

    local uv = require('luv')
    -- Create a timer in the worker thread
    local timer = uv.new_timer()

    -- Start the timer with an interval of 1 second
    timer:start(1000, 1000, function()
        print("Worker thread timer tick")
    end)

    msg=''
    -- Monitor the pipe for messages
    pipe_read:read_start(function(err, data)
        assert(not err, err)
        if data then
            local message = data:match("^%s*(.-)%s*$")
            if message == "pause" then
                print("Worker thread received 'pause' message")
                timer:stop()  -- Stop the timer
            elseif message == "resume" then
                print("Worker thread received 'resume' message")
                timer:start(1000, 1000)  -- Restart the timer
            elseif message == "stop" then
                print("Worker thread received 'stop' message")
                running = false
            end
        else
            pipe_read:close()
        end
    end)

    -- Run the event loop in the worker thread
    while running do
        uv.run('nowait')
    end

    -- Cleanup
    timer:stop()
    uv.stop()
    print("Worker thread event loop stopped")
end

-- Create a pipe for communication
local pipe_main_to_worker = uv.new_pipe(false)

-- Start the worker thread, passing the pipe for reading messages
local thread = uv.new_thread(timer_thread, pipe_main_to_worker)

-- Allow the worker thread to run for a few seconds
uv.sleep(3000)

-- Send a "pause" message to the worker thread
pipe_main_to_worker:write("pause\n")

-- Allow time for the pause to take effect
uv.sleep(3000)

-- Send a "resume" message to the worker thread
pipe_main_to_worker:write("resume\n")

-- Allow the worker thread to run for a few more seconds
uv.sleep(3000)

-- Send a "stop" message to terminate the worker thread
pipe_main_to_worker:write("stop\n")

-- Wait for the worker thread to finish
uv.thread_join(thread)

print("Main thread finished")
