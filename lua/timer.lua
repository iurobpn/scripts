local M = {}
-- local uv = require("luv")
local inspect = require("inspect")
require("class")

local luasocket = require('socket')
local Socket = require('socket')
local Log = require('log')

local Thread = require('thread')
local Timer = {
    name = "timer",
    ip = '127.0.0.1',
    port = 12345,
    socket = nil,
    elapsed_time = 0,
    start_time = 0,
    paused = false,
    running = false,
    alive = false,
    unit = "s"
}

-- Timer.__call = function(obj)
--     local self = setmetatable(obj, {__index = Timer})
--     return self
-- end

Timer = class(Timer,
    {
        constructor = function(self, ip, port, name)
            local mod_color = require('gruvbox-term').bright_blue
            self.name = name or Timer.name
            self.ip = ip or Timer.ip
            self.port = port or Timer.port

            self.socket = Socket(self.ip, self.port, -1, mod_color)
            self.log = Log("tclient")
            self.log.module_color = mod_color
            self.log:log("Client Timer created.")

            if not self.socket then
                self.log:error("Error creating socket.")
            else
                self.log:log("Socket created.")
            end

            return self
        end
    })

function Timer:join()
    if not self.thread then
        self.log:log("No active timer to join.")
        return
    end
    self.thread:join()
end

function Timer:restart()
    self.socket:send("restart")
end

-- Function to start the timer
function Timer:start()
    if self.thread and self.running then
        self.log:log("Timer is already running.")
        return
    end

    if self.paused then
        self.log:log("Timer paused.")
        return
    else
        -- local Thread = require('thread')
        self.elapsed_time = 0
        self.thread = Thread(function (ip, port, time_start, name, log_level)
            local Server = require('timer_server')
            local timer = Server(ip, port, time_start, name)
            if log_level then
                timer.log.log_level = log_level
            end
            timer:start(ip, port, time_start, name, log_level)
        end)

        self.start_time = clock.now()
        self.log:log("timer start time: " .. inspect(self.start_time) .. " seconds.")

        self.thread:start(self.ip, self.port, self.start_time, self.name, self.log.log_level)
        self.log:log("Thread started.")
        if not self.socket then
            self.log:error("Socket is empty on client start.")
        end
        -- self.log:log("Sending start message to server.")
        -- clock.sleep(0.1) -- self.socket.socket:sleep(0.5)
        -- self:send("start")
        self.log:log("Server started.")

        return self.start_time
    end
end



function Timer:pause()
    self.socket = luasocket.connect(self.ip, self.port)
    if not self.socket then
        self.log:error("connection error.")
        return
    else
        self.log:info(string.format("client connected at %s:%s", self.ip, self.port))
    end
    self.socket:send("pause")

    local msg = "pause\n"
    local _, err = self.socket:send(msg)
    if err then
        self.log:error("error sending message: ", err)
    else
        self.log:info("command sent to timer: ", msg)
    end
end

function Timer:resume()
    if not self.thread or not self.running then
        self.log:log("No active timer to resume.")
        return
    end

    if not self.paused then
        self.log:log("Timer is not paused.")
        return
    end

    self.socket:send("resume")
    self.log:log("Timer resumed.")
end


-- Method to send commands to the timer thread
function Timer:send(msg, noclose)

    self.log:log("Sending message to server: " .. msg)
    if not self.socket then
        self.log:error("Socket is empty on client start.")
    end
    self.log:log(string.format("Connecting to server at address %s:%s", self.ip, self.port))
    local client = self.socket:connect(self.ip, self.port)
    self.socket.socket = client

    if client then
        self.log:log("socket connected at " .. self.ip .. ":" .. self.port)
        local bytes, err = self.socket.socket:send(msg)
        if err then
            self.log:error("Error sending message: " .. err)
        else
            self.log:log("Message sent to server: " .. msg)
        end
    else
        self.log:error("socket connection error: " .. err)
    end
    -- self:check_connection()
    -- require'time'.sleep(0.1)  -- Prevent tight loop
    -- local serpent = require('serpent')
    return client
end

function Timer:receive()
    local client = self.socket:connect(self.ip, self.port)
    self.socket.socket = client
    local msg, err
    if client then
        msg, err = self.socket:receive()
        if err then
            if err == "closed" then
                self.log:error("Connection lost. Reconnecting...")
                self.socket:close()
            else
                self.log:error("Receive error: " .. err)
            end
        elseif msg then
            self.log:log("Received from server: " .. msg)
        end
    end
    require'time'.sleep(0.1) -- to prevent tight loop
    return msg, err
end


function Timer:stop()
    self.log:debug("stopping timer.")
    self.socket = luasocket.connect(self.ip, self.port)

    if self.socket then
        self.log:info(string.format("client connected at %s:%s", self.ip, self.port))
    else
        self.log:error("failed to connect to server.")
    end

    local msg = "stop\n"
    local _, err = self.socket:send(msg)
    if err then
        self.log:error(string.format("error sending message: ", err))
    else
        self.log:debug(string.format("message sent to server: ", msg))
    end

    local msg2, errr = self.socket:receive()
    if errr then
        self.log:error(string.format("error receiving message: %s", errr))
        return msg2, errr
    end

    self.log:debug(string.format("message received from server: ", msg2))
    self.elapsed_time = tonumber(msg2)
    self.log:info(string.format("timer stopped at %s s", self.elapsed_time))

    return self.elapsed_time, err
end

if vim then
    M.t = Timer()

    M.start = function()
        print("Timer start.")
        M.t:start()
    end
    M.stop = function()
        M.t:stop()
    end
    M.pause = function()
        M.t:pause()
    end

    -- Register the commands
    vim.api.nvim_create_user_command("Start", M.start, {})
    vim.api.nvim_create_user_command("Pause", M.pause, {})
    vim.api.nvim_create_user_command("Stop", M.stop, {})
end
M.Timer = Timer

return M
