local socket = require("socket")

-- Server settings
local host = "127.0.0.1"
local port = 12345
local server = assert(socket.bind(host, port))
server:settimeout(0)  -- Non-blocking mode

local clients = {}

print("Server running on " .. host .. ":" .. port)

while true do
    -- Accept new clients
    local new_client = server:accept()
    if new_client then
        new_client:settimeout(0)  -- Non-blocking mode
        table.insert(clients, new_client)
        print("New client connected.")
    end

    -- Prepare lists for select
    local ready_to_read = {server}
    for i, client in ipairs(clients) do
        ready_to_read[#ready_to_read + 1] = client
    end

    -- Use select to wait for activity with a timeout
    -- print("server socket " .. require("inspect")(server))
    local readable, _, err = socket.select(ready_to_read, nil, 0.1)

    -- if err then
    --     print("Select error: " .. err)
    -- end

    -- Handle readable clients
    for _, client in ipairs(readable) do
        if client == server then
            -- Skip the server socket itself, since it's handled above
        else
            local message, err = client:receive()
            if err then
                if err == "closed" then
                    print("Client disconnected.")
                    -- Remove client from the list
                    for i, c in ipairs(clients) do
                        if c == client then
                            table.remove(clients, i)
                            break
                        end
                    end
                    client:close()
                else
                    print("Receive error: " .. err)
                end
            elseif message then
                print("Received from client: " .. message)
                client:send("Echo: " .. message .. "\n")
            end
        end
    end
end
