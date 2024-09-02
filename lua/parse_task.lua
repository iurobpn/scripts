#!/usr/local/bin/lua
local M = {}
local json = require("dkjson") -- Assumes you have dkjson installed for JSON serialization

function M.parse_task(task) 
    local status_map = {
        ["[x]"] = "done",
        ["[v]"] = "in progress",
        ["[ ]"] = "not started"
    }

    -- Extract the status and remove it from the task string
    local status = task:match('%- %s*%[%s*([xv ])%s*%]')
    status = '[' .. status .. ']'

    status = status_map[status] or "not started yet"

    local parameters = {}

    local filename = task:match('[a-zA-ZçÇãõóéá]+.*%.md')
    local line_number = tonumber(task:match(':(%d+):'))
    local description = task:match('%-%s*%[x%]%s*([a-zA-Z0-9{][çÇãõóéáa-zA-Z0-9%s\",{}().%-]*)')
    local tags = {}
    for tag in task:gmatch('(#[a-zA-Z_%-]+)') do
        tags[#tags+1] = tag
    end
    for param, value in task:gmatch('[%[]([a-zA-Z_]+)%s*::%s*([a-zA-Z0-9][a-zA-Z0-9%s:%-]*)[%]]') do
        parameters[param] = value
    end

    local task_t = {
        filename = filename,
        line_number = line_number,
        status = status,
        description = description,
        tags = tags
    }
    for k, v in pairs(parameters) do
        task_t[k] = v
    end

    return task_t
end

-- Main function to handle input from stdin and output to stdout
function M.run()
    for line in io.lines() do
        -- Extract filename and line number
        local parsed_task = M.parse_task(line)
        local json_output = json.encode(parsed_task, { indent = true, level = 4 })  -- Pretty print with 4 spaces
        print(' ')
        print(line)
        print(json_output)
    end
end

-- Run the main function
-- main()

return M
