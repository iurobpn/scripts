local M = {}
M.lanes = require("lanes").configure()

M.Thread = {
    alive = false,
    thread = nil,
    func = nil,
    -- pipe = pipe
}

function M.Thread.start(self, ...)
    if self.thread and self.alive then
        print("Thread is already running.")
        return
    end
    self.alive = true
    self.thread = M.lanes.gen("*", self.func)
    self.thread(...)
end

function M.Thread.join(self)
    if not self.thread or not self.alive then
        print("No active thread to join.")
        return
    end
    -- Wait for the thread to finish
    -- M.ffi.C.pthread_join(self.thread[0], nil)
    self.alive = false
    -- self.thread[1]
    -- print("Thread joined.")
end

require('class').class(M.Thread, function(obj,func)
    obj.func = func
    return obj
end)

return M
