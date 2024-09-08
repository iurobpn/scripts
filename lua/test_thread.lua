local Thread = require 'thread'.Thread
local utils = require 'utils'
-- local function test_thread()
local thread = Thread(function()
    local time = require('time')
    -- local uv = require('luv')
    -- local socket = require 'socket'
    print("Thread started.")
    local k = 0
    for i = 1, 10 do
        print("Thread iter", i)
        time.sleep(1)
        k=k+1
    end
    -- print("Thread done.")
end)

print('\nThread obj tab')
utils.print_table(thread)

thread:start()
-- return thread

-- local thread = test_thread()

local time = require 'time'
-- local uv = require('luv')
-- print("\n main thread: stuff")
local k = 0;
-- for i=1,1000000000 do
for i=1,22 do
    time.sleep(0.5)
    -- uv.sleep(100)
    print('main thread iter ', i, k)
    i = i + 1
    k = k * i
end
print("\nMain thread done")

thread:join()

