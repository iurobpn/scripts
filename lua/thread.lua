
local uv= require('luv')
require('class')
-- local serpent = require('serpent')
-- local inspect = require('inspect')

require'utils'

local Thread = {
    running = false,
    thread = nil,
    func = function() print('empty function') end,
    alive = false
}

function Thread.start(self, ...)
    if self.thread and self.running then
        print("Thread is already running.")
        return
    end
    self.alive = true
    self.running = true
    self.thread = uv.new_thread(self.func, ...)
    -- print("Thread started.")
end

function Thread.join(self)
    if not self.thread or not self.running then
        print("No active thread to join.")
        return
    end
    self.thread:join()
    self.running = false
    -- print("Thread joined.")
end

Thread = class(Thread, function(obj, func)
    if func then
        obj.func = func
    end
    return obj
end)

return Thread
