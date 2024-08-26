local lanes = require("lanes").configure()
local linda = lanes.linda()

local function worker(linda)
    for i = 1, 5 do
        linda:send("channel", i)
        lanes.sleep(1)
    end
end

local lane = lanes.gen("*", worker)(linda)

for i = 1, 5 do
    local _, value = linda:receive("channel")
    print("Main thread received: " .. value)
end

