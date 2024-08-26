
local luasocket = require'socket'
local json = require'cjson'


-- a client creates its socket

local ip = "127.0.0.1"
local port = 12345
local client = luasocket.connect(ip, port)
if client then
    -- ip, port = client:getsockname()
    print(string.format("Client connected at %s:%s", ip, port))
else
    print("Failed to connect to server.")
end

-- send a message to the server
local msgs = {
    kill = true
}
local _, errs = client:send(json.encode(msgs) .. "\n")
if errs then
    print("Error sending message: ", errs)
else
    print("Message sent to server: ", msgs)
end

