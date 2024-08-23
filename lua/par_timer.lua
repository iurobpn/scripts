
local uv = require('luv')
local serpent = require('serpent')

local Timer = {
    elapsed_time = 0,
    start_time = 0,
    paused = false,
    running = false,
    timers = {},
    timer_id = 0,
}
Timer = require('class').class(Timer)

if not Timer then
    print('Timer is nil')
end

-- Private function to pause a specific timer
function Timer:_pause()
    self.paused = true
    print("Timer " .. self.timer_id .. " paused.")
end

-- Private function to stop a specific timer
function Timer:_stop()
    self.running = false
    self.timers[self.timer_id] = nil
    print("Timer " .. self.timer_id .. " stopped.")
end

-- Function to start a timer
function Timer:start(duration, callback)
    self.running = true
    self.paused = false
    self.start_time = uv.now()
    local target_time = self.start_time + duration
    self.timer_id = target_time
    self.timers[target_time] = callback
    print("Timer " .. self.timer_id .. " started for " .. duration .. "ms.")
end

-- Function to stop all timers
function Timer:stop_all()
    for id in pairs(self.timers) do
        self.timers[id] = nil
    end
    self.running = false
    print("All timers stopped.")
end

-- Function to pause all timers
function Timer:pause_all()
    self.paused = true
    print("All timers paused.")
end

-- Function to handle new timer commands
function Timer:new_timer(duration, callback)
    local target_time = uv.now() + duration
    self.timers[target_time] = callback
    print("New timer set for " .. duration .. "ms.")
end

-- Function to run the timer thread
function Timer.run(self)
    local k = 0
    while self.running do
        -- Read messages from the main thread
        print('Timer running it: ', k)
        k = k + 1
        self.pipe:read_start(function(err, data)
            assert(not err, err)
            if data then
                local message = serpent.load(data)
                if message.command == "pause" then
                    if message.timer_id then
                        if self.timers[message.timer_id] then
                            self:_pause()
                        end
                    else
                        self:pause_all()
                    end
                elseif message.command == "stop" then
                    if message.timer_id then
                        if self.timers[message.timer_id] then
                            self:_stop()
                        end
                    else
                        self:stop_all()
                    end
                elseif message.command == "new_timer" then
                    self:new_timer(message.duration, message.callback)
                end
            else
                self.pipe:close()
            end
        end)

        -- Check and execute timers
        local now = uv.now()
        local next_target = nil
        for target_time, callback in pairs(self.timers) do
            if target_time <= now then
                callback()
                self.timers[target_time] = nil
            elseif not next_target or target_time < next_target then
                next_target = target_time
            end
        end

        -- Sleep for a short time to avoid busy waiting
        if next_target then
            local sleep_time = next_target - now
            if sleep_time > 0 then
                uv.sleep(math.min(sleep_time, 100)) -- sleep max 100ms or until next target
            end
        else
            uv.sleep(100) -- sleep for 100ms if no timers are left
        end
    end
    uv.stop()
end

-- Method to send commands to the timer thread
function Timer:send(pipe, command, timer_id, duration, callback)
    local message = { command = command, timer_id = timer_id, duration = duration, callback = callback }
    local serialized = serpent.dump(message)
    pipe:write(serialized .. "\n")
end

if not Timer then
    print('Timer is nil')
else
    print('Timer is not nil')
end
-- Function to create a new Timer object and start it in a new thread
function Timer.start_timer_thread(self)
    self.pipe = uv.new_pipe(false)
    self.thread = require('thread').Thread(function(obj)
        obj:run()
    end, self)

    -- Return the thread and pipe for command communication
    return self.thread, self.pipe
end

return Timer
