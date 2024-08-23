local uv = require('luv')

-- Shared data
local shared_message = ""
local mutex = uv.new_mutex()

-- Function to run in the first thread
local function thread1()
    local uv = require('luv')
    for i = 1, 5 do
        uv.sleep(500) -- Sleep for 0.5 seconds

        -- Lock the mutex to safely write to shared memory
        mutex:lock()
        shared_message = "Message from Thread 1 - count: " .. i
        print("Thread 1 set message:", shared_message)
        mutex:unlock()
    end
end

-- Function to run in the second thread
local function thread2()
    local uv = require('luv')
    for i = 1, 5 do
        uv.sleep(700) -- Sleep for 0.7 seconds

        -- Lock the mutex to safely read from shared memory
        mutex:lock()
        if shared_message ~= "" then
            print("Thread 2 read message:", shared_message)
            shared_message = ""  -- Clear the message after reading
        end
        mutex:unlock()
    end
end

-- Start Thread 1
local thread1_handle = uv.new_thread(thread1)

-- Start Thread 2
local thread2_handle = uv.new_thread(thread2)

-- Wait for both threads to finish
uv.thread_join(thread1_handle)
uv.thread_join(thread2_handle)

print("Main thread finished")
