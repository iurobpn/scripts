
-- Example JSON data
local json_data = [[
{
    "filename": "example.txt",
    "line_number": 42,
    "status": "done",
    "description": "task description",
    "tags": ["#tag1", "#tag2"],
    "some_parameter": "some value with spaces"
}
]]

-- Parse JSON to Lua table
local task_data, pos, err = json.decode(json_data, 1, nil)

if err then
    print("Error:", err)
else
    -- Insert the parsed data into the database
    insert_data(task_data)
end

-- SELECT * FROM tasks;
-- SELECT tag FROM tags WHERE task_id = 1;
-- SELECT parameter_name, parameter_value FROM parameters WHERE task_id = 1;
