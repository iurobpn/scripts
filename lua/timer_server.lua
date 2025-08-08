-- local inspect = require("inspect")
require('time')
require('katu.utils')
local json = require('dkjson')
require'class'

local luasocket = require('socket')
local Log = require('dev.lua.log')

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

local message = {
    client_id = 0,
    task_id = 0,
    timer_id = 0,
    msg = {
        cmd = nil, -- timers: start, pause, resume, stop, restart, get and set (vars not only timers)
        cmd_args = nil, -- timer_id, start_time, elapsed_time, remaining_time, total_time
    },
}

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

Server = _G.class(Server, function(ip, port, time_start, name, log_file)
    local self = {}
    local mod_color = require('gruvbox-term').bright_orange

    if ip then
        self.ip = ip
    end
    if port then
        self.port = port
    end

    self.log = Log("tserver")
    self.log:set_file(log_file)
    self.log.module_color = mod_color
    self.log:info("server created.")
    if time_start then
        if not self.timer then
            self.log:debug("timer not initialized")
            self.timer = {}
        end
        self.timer[1] = TimerData({start_time = time_start, elapsed_time = 0, running = false, paused = false, unit = "s"})
        self.log:debug("self.timer: " .. require('inspect')(self.timer))
    end

    self.name = name or self.name

    return self
end)

TimerData = {
    id = 0,
    client_id = 0,
    task_id = 0,
    mode = "countup",
    start_time = 0,
    elapsed_time = 0,
    remaining_time = 0,
    stop_time = 0,
    paused = false,
    running = false,
    unit = "s"
}
-- mode, start_time, elapsed_time, duration, paused, running, unit)
TimerData = _G.class(TimerData, 
    {
        constructor = function(...)
            local self = {}
            local opt = {...}
            opt = opt[1] or {}
            local targs = opt
            if targs.timer then
                targs = targs.timer
            end
            for k, v in pairs(targs) do
                self[k] = v or self[k]
            end
            self.client_id = arg.client_id or 0
            self.task_id = arg.task_id or 0
            self.remaining_time = targs.duration
            if not self.start_time or self.start_time <=0 then
                self.start_time = clock.now()
            end

            return self
        end
    })

function Server:get_id()
    self.id = self.id + 1
    return self.id
end

function Server:parse(client,data)
    -- local client, data = unpack(message)
    if data then
        self.log:debug("decoding message: " .. data)
        -- local msg = data:match("^%s*(.-)%s*$")
        -- msg = split(msg,":")

        local msg = ''
        local data2 = data
        if data ~= nil and data ~= '' then
            msg = json.decode(data2)
            self.log:debug(string.format("raw data2 msg str: %s", data2))
            self.log:debug(string.format("raw data msg str: %s", data))
            self.log:debug(string.format("msg converted to json: %s", require('inspect').inspect(msg)))
        end
        local id
        if msg.timer then
            if msg.timer.start then
                msg.timer.id = self.get_id();
                id = msg.timer.id
                self.timer[id] = TimerData(msg)
                self.timer[id].running = true

                msg = {
                    client_id = self.timer[id].client_id,
                    timer = {
                        id = id,
                        start_time = self.timer[id].start_time
                    }
                }
                self.send(client, json.encode(msg) .. '\n')
                -- self:add_timer(id)
            end
            if msg.get then
                id = msg.timer.id

                out = {}
                out.timer = {}
                for k, v in pairs(msg.get) do
                    out[k] = self.timer[id][k]
                end

                self.send(client, out)
            elseif msg.set then
                id = msg.timer.id
                for k, v in pairs(msg.set) do
                    self.timer[id][k] = v
                end
            elseif msg.pause then
                self:pause(msg.timer.id)
            elseif msg.restart then
                if #msg > 1 then
                    self.timer[id].start_time = tonumber(msg[2])
                else
                    self.timer[id].start_time = clock.now()
                    self.log:warn("start time is more accurate if provided by client")
                end
                self:restart(msg.timer.id,client)
            elseif msg.resume then
                self:resume(msg.timer.id)
            elseif msg.stop then
                self:stop(msg.timer.id,client)
            else
                self.log:warn("received invalid message: " .. data)
            end
        end
        if msg.task then
            if msg.task.start then
                msg.task.id = self.get_id();
                id = msg.task.id
                self.taks[id] = TaksData(msg)
                self:add_taks(id)
            end
        end
        if msg.kill then
            self.log:info("server received kill message.")
            self.running = false
        end

    else
        self.log:trace("server received empty message.")
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
        self.log:trace("server is already running.")
        return
    end
    self.running = true

    if self.timer[id].paused then
        self.log:info(string.format("timer %d paused.", id))
        return
    end
    self.timer[id].running = true
    self.ip = ip or self.ip
    self.port = port or self.port
    if not time_start or time_start == 0 then
        if not self.start_time then 
            if not self.timer[id].start_time then
                self.log:warn('Start time is zero, please set a start time.') -- if not time_start then
                time_start = clock.now()
                self.log:warn('setting start time to now: ' .. time_start) -- if not time_start then
            else
                time_start = self.timer[id].start_time
            end
        else
            time_start = self.start_time
        end
        self.log:error('Start time is nill or zero, please set a start time.') -- if not time_start then
    end
    self.start_time = time_start
    if not self.timer and not self.timer[1] then
        self.timer = {}
        self.timer[1] = TimerData()
    end
    self.timer[1].start_time = self.start_time
    self.log:debug("server started at " .. clock.now() .. " with client time start at " .. (time_start or self.start_time) .. " seconds")

    self.timer[id].start_time = time_start

    -- local inspect = require('inspect')
    require'katu.utils'
    -- self.log:trace(time_start)
    self:config(id)
    self.socket = assert(luasocket.bind(ip, port))
    self.socket:settimeout(0)
    self.log:info('Server started at ' .. clock.now() .. ' with client time start at ' .. (time_start or self.start_time) .. ' seconds')
    self.log:info('Server listening to ' .. self.ip .. ':' .. self.port)
    -- if not self.socket then
    --     self.socket = Socket(self.ip, self.port)
    -- end

    -- local client = self.socket:accept()

    local i = 0
    self.log:debug("starting loop\n")
    while self.running do
        self.log:trace(self.name .. " iter " .. i)
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
        self.log:trace('new client connected')
        -- clock.sleep(0.1)
    else
        self.log:trace('no new clients connected')
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
                self.log:debug("received new message from client " .. require('inspect').inspect(client) .. ": " .. message)
                -- table.insert(messages, {client, message})
                self:parse(client,message)
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
        local msg = {
            client_id = self.timer[id].client_id,
            timer = {
                id = id,
                elapsed_time = self.timer[id].elapsed_time
            }
        }
        if self:send(client, json.encode(msg) .. '\n') then
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
        local msg = {
            client_id = self.timer[id].client_id,
            timer = {
                id = id,
                elapsed_time = self.timer[id].elapsed_time
            }
        }
        if self:send(client, json.encode(msg) .. '\n') then
            self.log:info(string.format('timer %d stopping, elapsed time sent to client: %s seconds', id, self.timer[id].elapsed_time))
        end
    else
        self.log:info(string.format('timer %d stopping, client disconnected, elapsed time: %s seconds', id, self.timer[id].elapsed_time))
    end
    self.timer[id].elapsed_time = 0
    self.timer[id].start_time = 0

    -- Stop the Server by killing the thread
end
Server.TimerData = TimerData

return Server

