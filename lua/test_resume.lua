
local luasocket = require'socket'


-- a client creates its socket

local ip = "127.0.0.1"
local port = 12345
local client = luasocket.connect(ip, port)
if client then
    ip, port = client:getsockname()
    print(string.format("Client connected at %s:%s", ip, port))
else
    print("Failed to connect to server.")
end

-- send a message to the server
local msgs = "resume\n"
local _, errs = client:send(msgs)
if errs then
    print("Error sending message: ", errs)
else
    print("Message sent to server: ", msgs)
end

if msgs == "stop\n" then
    -- receive a message from the server
    local msgr, errr = client:receive()
    if errr then
        print("Error receiving message: ", errr)
    else
        print("Message received from server: ", msgr)
    end

end
