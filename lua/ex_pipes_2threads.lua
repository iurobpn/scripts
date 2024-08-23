local uv = require('luv')

-- Function to run in the first thread
local function thread1(pipe_read, pipe_write)
    local uv = require('luv')  -- Ensure the proper scope inside the thread

    -- Read from the pipe connected to the main thread
    pipe_read:read_start(function(err, data)
        if data then
            print("Thread 1 received:", data)
            -- Respond to thread 2
            local response = "Hello from Thread 1"
            pipe_write:write(response .. "\n")
        else
            pipe_read:close()
            pipe_write:close()
        end
    end)

    -- Start the event loop in this thread
    uv.run()
end

-- Function to run in the second thread
local function thread2(pipe_read, pipe_write)
    local uv = require('luv')  -- Ensure the proper scope inside the thread

    -- Read from the pipe connected to thread 1
    pipe_read:read_start(function(err, data)
        if data then
            print("Thread 2 received:", data)
            -- Respond to thread 1
            local response = "Hello from Thread 2"
            pipe_write:write(response .. "\n")
        else
            pipe_read:close()
            pipe_write:close()
        end
    end)

    -- Start the event loop in this thread
    uv.run()
end

-- Create two pairs of pipes for communication
local pipe1_to_2 = uv.new_pipe(false) -- For Thread 1 to Thread 2 communication
local pipe2_to_1 = uv.new_pipe(false) -- For Thread 2 to Thread 1 communication

-- Start Thread 1
local thread1_handle = uv.new_thread(thread1, pipe1_to_2, pipe2_to_1)

-- Start Thread 2
local thread2_handle = uv.new_thread(thread2, pipe2_to_1, pipe1_to_2)

-- Send an initial message from the main thread to Thread 1
uv.sleep(100)  -- Ensure the threads are ready before sending data
pipe1_to_2:write("Hello from Main Thread\n")

-- Let the threads exchange a few messages
uv.sleep(2000)

-- After a few exchanges, stop the event loops by closing the pipes
pipe1_to_2:close()
pipe2_to_1:close()

-- Wait for both threads to finish
uv.thread_join(thread1_handle)
uv.thread_join(thread2_handle)

print("Main thread finished")
