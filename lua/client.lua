local socket = require("socket")

local id = arg[1] or 1

-- Server address
local host = "127.0.0.1"
local port = 12345
local client
local N = 10
local k = 0

local Client

while true do
    print('iter ', k)
    -- Keep trying to connect to the server
    -- while true do
        client = socket.connect(host, port)
        if client then
            -- client:settimeout(0)  -- Non-blocking mode
            print(string.format("client %d Connected to server.", id))
            -- break
        else
            print("Failed to connect, retrying in 2 seconds...")
            socket.sleep(2)  -- Wait 2 seconds before trying aga
            break;
        end
    -- end

    -- Send a message to the server
    local _, err client:send("stop\n")
    if err then
        print("Send error: " .. err)
        break
    else
        print("Sent to server: stop")
    end

    -- Receive the echoed message from the server
    -- while true do
    client:settimeout()
        local response, error = client:receive()
        if error then
            if error == "closed" then
                print("Server disconnected.")
                break
            else
                print("Receive error: " .. error)
            end
        elseif response then
            print("Received from server: " .. response)
            -- break
        end

        -- socket.sleep(0.1)  -- Sleep to prevent tight loop
    -- end
    -- socket.sleep(1)
    print(string.format("Client iter %d...",k))
    if k > N then
        break
    end
    k = k + 1
end
client:close()
print("Client finished")
