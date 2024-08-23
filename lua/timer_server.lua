-- local inspect = require("inspect")
require('time')
require('utils')

local luasocket = require('socket')
local Log = require('log')

-- server communication:
-- kill() -- stop the server
-- count up timer: {
--    start[:start_time] -- return id if started via network
--    id:pause
--    id:resume
--    id:restart
--    id:stop -- return elapsed_time
--    id:get:elapsed_time
--    id:get:start_time
--
-- }
-- count down timer: {
--   start[:start_time] -- return id if started via network
--   id:pause
--   id:resume
--   id:stop
--   id:restart:start_time
--   id:get:elapsed_time
--   id:get:remaining_time
--   id:get:total_time
--   }

local Server = {
    name = "server",
    id = 0,
    socket = nil,
    ip = "127.0.0.1",
    port = 12345,
    timeout = 0,
    timer = {},
    paused = false,
    running = false,
    clients = {},
    unit = "s"
}

Server = require('class').class(Server, function(self, ip, port, time_start, name)
    local mod_color = require('gruvbox-term').bright_orange

    if ip then
        self.ip = ip
    end
    if port then
        self.port = port
    end

    local id = 1

    if time_start then
        self.timer[id].start_time = time_start
        self.timer[id].elapsed_time = 0
    end
    self.name = name or self.name

    self.timer[id].running = false
    self.timer[id].paused = false
    self.log = Log("tserver")
    self.log.module_color = mod_color
    self.log:log("server created.")

    return self
end)

local TimerData = {
    start_time = 0,
    elapsed_time = 0,
    remaining_time = 0,
    paused = false,
    running = false,
    unit = "s"
}

TimerData = require('class').class(TimerData, function(self, mode, start_time, elapsed_time, duration, paused, running, unit)
    self.mode = mode or self.mode
    self.start_time = start_time or self.start_time
    self.paused = false
    self.running = false
    self.unit = unit or self.unit
    return self
end)

function Server:get_id()
    self.id = self.id + 1
    return self.id
end

function Server:decode_message(client,data)
    -- local client, data = unpack(message)
    self.log:debug("decoding message." .. data)
    if data then
        local msg = data:match("^%s*(.-)%s*$")
        msg = split(msg,":")
        local id = tonumber(msg[1])
        local message
        if not id then
            message = msg[1]
            id = self.get_id();
            self.timer[id] = TimerData()
        else
            self.log:debug("received message from client for timer id: " .. id)
            message = msg[2]
        end
        
        self.log:debug("received message: " .. message)
        if message == "pause" then
            self:pause()
        elseif message == "kill" then
            self.timer[id].running = false
        elseif message == "get" then
            local req_var = msg[2]
            if req_var == "elapsed_time" then
                self:send(client, tostring(self.timer[id].elapsed_time))
            elseif req_var == "start_time" then
                self:send(client, tostring(self.timer[id].start_time))
            elseif req_var == "remaining_time" then
                self:send(client, tostring(self.timer[id].remaining_time))
            end
        elseif message == "restart" or message == "start" then
            if #msg > 1 then
                self.timer[id].start_time = tonumber(msg[2])
            else
                self.timer[id].start_time = clock.now()
                self.log:warn("start time is more accurate if provided by client")
            end
            self:restart(id,client)
        elseif message == "resume" then
            self:resume(id)
        elseif message == "stop" then
            self:stop(id,client)
        else
            self.log:warn("received invalid message: " .. message)
        end
    else
        self.log:log("server received empty message.")
    end
end

function Server:new_timer(mode, start_time, duration, func, ...)
    local id = self.get_id()
    self.timer[id] = TimerData(mode, start_time, 0, duration, false, false, "s")
    if mode == "countdown" then
        self.timer[id].duration = duration
        self.deadlines[id] = start_time + duration
        self.log:info("new countdown timer created with id: " .. id)
    else
        self.log:info("new countup timer created with id: " .. id)
    end

    return id
end

-- start server
function Server:start(ip, port, mode, time_start, duration, func, ...)
    local id = 1
    if #self.timer == 0 then
        id = self:new_timer( mode, time_start, duration, func, ...)
    end
    if self.running then
        self.log:log("server is already running.")
        return
    end

    if self.timer[id].paused then
        self.log:info(string.format("timer %d paused.", id))
        return
    end
    self.timer[id].running = true
    self.ip = ip or self.ip
    self.port = port or self.port
    self.log:debug("server started at " .. clock.now() .. " with client time start at " .. time_start .. " seconds")
    if time_start == 0 and self.timer[1].start_time == 0 then
        self.log:error('Start time is zero, please set a start time.') -- if not time_start then
        time_start = clock.now()
        self.log:warn('setting start time to now: ' .. time_start) -- if not time_start then
    else
        if self.timer[1].start_time ~= 0 then
            time_start = self.timer[1].start_time
        end
    end

    self.timer[id].start_time = time_start

    -- local inspect = require('inspect')
    require'utils'
    -- self.log:log(time_start)
    self:config(id)
    self.socket = assert(luasocket.bind(ip, port))
    self.socket:settimeout(0)
    self.log:info('Server started at ' .. clock.now() .. ' with client time start at ' .. time_start .. ' seconds')
    self.log:info('Server listening to ' .. self.ip .. ':' .. self.port)
    -- if not self.socket then
    --     self.socket = Socket(self.ip, self.port)
    -- end

    -- local client = self.socket:accept()

    local i = 0
    self.log:debug("starting loop\n")
    while self.running do
        self.log:debug(self.name .. " iter " .. i)
        local readable = self:select() -- select readable clients using socket:select
        self:listen(readable) -- listen and process client messages

        i = i + 1

        clock.sleep(0.1)
        -- if not self.timer[id].paused then
        --     local t_now = math.floor(clock.now() - self.timer[id].start_time)
        --     self.log:trace(t_now .. " s")
        -- end
    end
    self.log:info('server stopped')
end

function Server:select()
    local new_client = self.socket:accept()
    if new_client then
        -- new_client.settimeout(0)
        table.insert(self.clients, new_client)
        self.log:log('new client connected')
        -- clock.sleep(0.1)
    else
        self.log:log('no new clients connected')
    end

    local ready_to_read = {self.socket}

    if #self.clients > 0 then
        self.log:trace("clients connected: " .. #self.clients)
        for _, client in ipairs(self.clients) do
            ready_to_read[#ready_to_read + 1] = client
        end
        self.log:trace("ready to read clients list: " .. #ready_to_read)
    else
        self.log:trace("no clients connected.")
    end

    -- Use select to wait for activity with a timeout
    if #ready_to_read == 0 then
        self.log:trace("no clients to read from.")
        return {}
    elseif #ready_to_read == 1 and ready_to_read[1] == self.socket then
        self.log:trace("only the server is ready to read.")
    end
    self.log:trace("server socket inspection." ..require('inspect')(self.socket))
    local readable, _, err = luasocket.select(ready_to_read, nil, 0)
    self.log:trace("readable clients list: " .. #readable)

    if err then
        self.log:trace("select: " .. err)
    end
    return readable
end

function Server:listen(readable)
    local messages = 0
    -- Handle readable clients
    for _, client in ipairs(readable) do
        if client == self.socket then
            self.log:trace("server socket is ready to read.")
            -- Skip the server socket itself, since it's handled above
        else
            self.log:trace("client is ready to read.")
            client:settimeout(0)
            local message
            local err
            message, err = client:receive()
            if err then
                if err == "closed" then
                    self.log:trace("client disconnected.")
                    -- Remove client from the list
                    for i, c in ipairs(self.clients) do
                        if c == client then
                            table.remove(self.clients, i)
                            break
                        end
                    end
                    client:close()
                else
                    self.log:error("receive error: " .. err)
                    if not message then
                        self.log:error("message is nil.")
                    end
                    -- print(' a' .. self.err)
                end
            elseif message then
                self.log:debug("received new message from client " .. require'inspect'.inspect(client) .. ": " .. message)
                -- table.insert(messages, {client, message})
                self:decode_message(client,message)
                messages = messages + 1

                -- print(' an' .. self.ok)
            end
            -- print('a' .. self.ok)
        end
    end
    self.log:trace("server received " .. messages .. " messages.")
end


-- Function to restart the Server
function Server:restart(id)
    if not self.timer[id].running then
        self.log:info(string.format("timer %d is not active.", id))
        return nil
    end

    self.timer[id].elapsed_time = 0

    self.timer[id].paused = false
    self.log:info(string.format("timer restarted at %s s", self.timer[id].start_time))
    return true
end

-- Function to start the Server
function Server:config(id)
    self.timer[id].elapsed_time = 0
    self.timer[id].running = true
    self.timer[id].paused = false
    if not self.timer[id].start_time then
        self.timer[id].start_time = clock.now()
    end
end

function Server:resume(id)
    if not self.timer[id] then
        self.log:info(string.format("timer %d is not registered.", id))
        return
    end
    if not self.timer[id].running then
        self.log:trace(string.format("timer %d is not active.", id))
        return
    end

    if not self.timer[id].paused then
        self.log:debug(string.format("timer %d received pause command, but server is not paused.", id))
        return
    end

    self.timer[id].start_time = clock.now() - self.timer[id].elapsed_time
    self.log:info(string.format("timer %d resumed at %f s", id, self.timer[id].elapsed_time))
    self.timer[id].paused = false
end

-- Function to pause the Server
function Server:pause(id)
    if not self.timer[id] then
        self.log:info(string.format("timer %d is not registered.", id))
        return
    end
    if not self.timer[id].running then
        self.log:info(string.format("timer %d is not running", id))
        return
    end

    if self.timer[id].paused then
        self.log:info(string.format("timer %d is already paused.", id))
        return
    end
    self.log:debug(string.format("timer[%d]: elapsed time before %s seconds", id, self.timer[id].elapsed_time))
    self.log:debug(string.format("timer[%d]start time before %s seconds", id, self.timer[id].start_time))
    self.timer[id].elapsed_time = self.timer[id].elapsed_time + clock.now() - self.timer[id].start_time

    self.timer[id].paused = true
    self.log:info(string.format("paused at %s seconds", self.timer[id].elapsed_time))
end

function Server:send(client, message)
    local _, err = client:send(message .. '\n')
    if err then
        self.log:error(string.format("error sending message: %s", err))
        return nil
    else
        self.log:debug(string.format("message: %s sent to client", message))
        return true
    end
end
-- Function to stop the Server and get the self.elapsed time
function Server:stop(id,client)
    self.log:debug('Server: stop() called')
    if not self.timer[id].running then
        self.timer[id].running = false
        if not self.timer[id].paused then
            self.log:trace(string.format("timer %d has not started", id))
        else
            self.log:info(string.format("timer %d is paused",id))
        end
        return
    end
    if self.timer[id].start_time == 0 then
        self.log:info(string.format("timer %d is already stopped", id))
        self.timer[id].elapsed_time = 0
        if self:send(client, tostring(self.timer[id].elapsed_time)) then
            self.log:debug(string.format("timer id: elapsed time successully sent to client: %s seconds", id, self.timer[id].elapsed_time or 0))
        end
        return
    end


    if not self.timer[id].paused then
        self.timer[id].elapsed_time = clock.now() - self.timer[id].start_time + self.timer[id].elapsed_time
    end
    self.log:debug(string.format("timer %d stopping:", id))
    self.log:debug(string.format("timer %d start time: %s s", id, self.timer[id].start_time))
    self.log:debug(string.format("timer %d elapsed time: %s s", id, self.timer[id].elapsed_time))
    self.timer[id].paused = false

    if client then
        -- client:settimeout(-1)
        if self:send(client, tostring(self.timer[id].elapsed_time)) then
            self.log:info(string.format('timer %d stopping, elapsed time sent to client: %s seconds', id, self.timer[id].elapsed_time))
        end
    else
        self.log:info(string.format('timer %d stopping, client disconnected, elapsed time: %s seconds', id, self.timer[id].elapsed_time))
    end
    self.timer[id].elapsed_time = 0
    self.timer[id].start_time = 0

    -- Stop the Server by killing the thread
end

return Server

