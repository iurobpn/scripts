local json = require("dkjson") -- Assumes you have dkjson installed for JSON serialization

local function parse_task(task, filename, line_number)
    local status_map = {
        ["[x]"] = "done",
        ["[v]"] = "in progress",
        ["[ ]"] = "not started"
    }
    
    -- Extract the status and remove it from the task string
    local status = status_map[task:sub(3, 5)] or "not started"
    task = task:sub(8)  -- Remove the '- [x] ', '- [v] ', or '- [ ] ' prefix
    
    local description = {}
    local tags = {}
    local parameters = {}
    
    for word in task:gmatch("%S+") do
        if word:sub(1, 1) == "#" then
            table.insert(tags, word)
        elseif word:match("^%[.*::.*%]$") then
            -- Remove the brackets and split the parameter and value, handling spaces
            local param, value = word:match("^%[(.-)%s*::%s*(.-)%]$")
            if param and value then
                parameters[param:match("^%s*(.-)%s*$")] = value:match("^%s*(.-)%s*$")
            end
        else
            table.insert(description, word)
        end
    end
    
    local result = {
        filename = filename,
        line_number = tonumber(line_number),
        status = status,
        description = table.concat(description, " "),
        tags = tags
    }
    
    for k, v in pairs(parameters) do
        result[k] = v
    end
    
    return result
end

-- Main function to handle input from stdin and output to stdout
local function main()
    for line in io.lines() do
        -- Extract filename and line number
        local filename, line_number, task = line:match("^(.-):(%d+):%s*(.*)$")
        if filename and line_number and task then
            local parsed_task = parse_task(task, filename, line_number)
            local json_output = json.encode(parsed_task, { indent = true, level = 4 })  -- Pretty print with 4 spaces
            print(json_output)
        else
            io.stderr:write("Invalid input format: ", line, "\n")
        end
    end
end

-- Run the main function
main()
