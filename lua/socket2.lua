local luasocket = require('socket')
local Log = require('log')

local Socket = {
    socket = nil,
    ip = "127.0.0.1",
    port = 12345,
    timeout = 0.1
}

function Socket:bind(ip, port)
    self.ip = ip or self.ip
    self.port = port or self.port
    local luasocket = require('socket')
    self.socket = assert(luasocket.bind(ip, port))
    self.socket:settimeout(0)  -- Non-blocking mode
    self.ip, self.port = self.socket:getsockname()
    self.log:log("Binding to " .. self.ip .. ":" .. self.port)
end

Socket = require('class').class(Socket, function(self, ip, port, timeout, color)

    self.ip = ip or Socket.ip
    self.port = port or Socket.port
    self.timeout = timeout or Socket.timeout
    self.log = Log('socket')
    if not color then
        self.log.module_color = require('gruvbox-term').bright_aqua
    else
        self.log.module_color = color
    end
    self.log:log('socket created')
    -- self.socket = assert(require('socket').bind(self.ip, self.port))

    return self
end)

function Socket:send(data)
    if self.socket then
        self.log:log("sending data")
        self.socket:send(data)
        self.log:log("data sent")
    else
        self.log:log("socket not connected")
    end
end

function Socket:accept()
    if self.socket then
        self.log:log("accepting socket")
        self.socket:settimeout(0)
        local client, err = self.socket:accept()
        if not client then
            self.log:error("error accepting client: ")-- .. err)
        else
            self.log:log("socket accepted")
            self.log:log("client: " .. require'inspect'.inspect(client, {depth = 3}))
        end
        return client, err
    else
        self.log:error("socket is nil")
        return nil, nil
    end
end

function Socket:close()
    if self.socket then
        self.socket:close()
        self.log:log("socket closed")
    end
end


function Socket:settimeout(timeout)
    if self.socket then
        self.socket:settimeout(timeout)
    end
end

function Socket:receive()
    if self.socket then
        return self.socket:receive()
    end
end

-- return lists of sockets that are ready to read or write
-- can be used with client on both lists in case of one server, one client communication
function Socket:select(recvs, sends, timeout)
    if not self.socket then
        self.log:error("socket not connected")
        -- self:connect(self.ip, self.port)
        return nil
    else
        self.log:log("socket is present")
    end
    self.log:log("selecting sockets")
    if not recvs then
        self.log:log('receive list with 0 sockets')
    else
        self.log:log('receive list with ' .. #recvs .. ' sockets')
    end
    if not sends then
        self.log:log('send list with 0 sockets')
    else
        self.log:log('send list with ' .. #sends .. ' sockets')
    end
    -- if timeout == nil then
    --     timeout = self.timeout
    -- end
    self.log:log("Timeout set to " .. timeout)
    -- self.log:log('Socket inpection: ' .. require'inspect'.inspect(self.socket, {depth = 3}) .. ' ' .. type(self.socket))
    self.socket:settimeout(timeout)
    local ip, port = self.socket:getsockname()
    self.log:log("socket ip: " .. ip .. ":" .. port)
    return self.socket.select(recvs, sends, timeout)
end

function Socket:listen(client)
    local out = false
    self.log:log('checking if client is listening')
    if client then
        local ip, port = client:getsockname()
        self.log:log("client ip address: " .. ip .. ":" .. port)
        local message, err = client:receive()
        if message then
            self.log:log('client received empty message with errot: ' .. err)
        else
            self.log:error('client received message: ' .. message .. ' with error: ' .. err)
        end
        self.log:log('client received message: ' .. message .. ' with error: ' .. err)
        if not err then
            self.log:log("Server received: " .. message)
            out = true
        else
            self.log:error("Server error while listening: " .. err)
            out = false
        end
    else
        client = self.socket:accept()
        self.log:error('client not connected')
        out = false
    end
    return out, msg, client
end

function Socket:connect(ip, port)
    self.ip = ip or self.ip
    self.port = port or self.port
    local client = assert(luasocket.connect(ip, port))
    if client then
        self.log:log("client connected to " .. self.ip .. ":" .. self.port)
    else
        self.log:error("client connection error")
    end
    return client
end

function Socket:getsockname()
    if self.socket then
        return self.socket:getsockname()
    end
end

return Socket
