local uv = require('luv')
local log = require('log')

-- Function to run in the server thread
local function server_thread()
    local log = require('log')
    log.module = "Server"
    local time = require('time')
    local uv = require('luv')
    local socket = require('socket')
    local server = assert(socket.bind("127.0.0.1", 12345))
    -- server:settimeout(1)  -- Set timeout to 5 seconds
    local ip, port = server:getsockname()
    log:log("Server listening on " .. ip .. ":" .. port)
    server:settimeout(1) -- Set timeout to 5 seconds
    local client = server:accept()

    while true do
        time.sleep(0.5)
        if client then
            local ip, port = client:getsockname()
            log:log("Client connect on " .. ip .. ":" .. port)
            local message, err = client:receive()
            if not err then
                log:log("Server received:" .. message)
                client:send("Acknowledged: " .. message .. "\n")
            end
        else
            client = server:accept()
            print('ops: client not connected')
        end
    end
    client:close()
end

-- Function to run in the client thread
local function client_thread()
    local log = require('log')
    log.module = "Client"
    local uv = require('luv')
    local socket = require('socket')
    local time = require('time')
    uv.sleep(1000)  -- Give the server some time to start

    local client = assert(socket.connect("127.0.0.1", 12345))
    client:settimeout(1)  -- Set timeout to 5 seconds

    local k = 0
    local t_sleep = 0.5
    while true do
        client:send("Hello from Client\n")
        local response, err = client:receive()
        if not err then
            log:log("Client received:" .. response)
        end
        if (k % 10 == 0) then
            time_sleep = 0.1
            log:log("Client sending message number: " .. k)
        end
        time.sleep(time_sleep)
        k = k + 1
    end


    client:close()
end

-- Start the server thread
local server_handle = uv.new_thread(server_thread)

-- Start the client thread
local client_handle = uv.new_thread(client_thread)

-- Wait for both threads to finish (for this example, they run indefinitely)
uv.thread_join(server_handle)
uv.thread_join(client_handle)

log:log("Main thread finished")

