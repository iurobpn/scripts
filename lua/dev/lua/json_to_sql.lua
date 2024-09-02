local M = {}
local json = require("dkjson")
local luasql = require("luasql.sqlite3")


function M.create_table()
    -- Connect to (or create) the SQLite database
    local env = luasql.sqlite3()
    local conn = env:connect("tasks.db")
    -- Create a table to store the JSON data
    local create_table_sql = [[
CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filename TEXT,
    line_number INTEGER,
    status TEXT,
    description TEXT
);
CREATE TABLE IF NOT EXISTS tags (
    task_id INTEGER,
    tag TEXT,
    FOREIGN KEY(task_id) REFERENCES tasks(id)
);
CREATE TABLE IF NOT EXISTS parameters (
    task_id INTEGER,
    parameter_name TEXT,
    parameter_value TEXT,
    FOREIGN KEY(task_id) REFERENCES tasks(id)
);
]]
    conn:execute(create_table_sql)
    -- Close the connection
    conn:close()
    env:close()
end

function M.query(query)
    local env = luasql.sqlite3()
    local conn = env:connect("tasks.db")

    -- Get the last inserted task_id
    local cursor = conn:execute(query)
    local task_id = cursor:fetch()
    -- Close the connection
    conn:close()
    env:close()
end

-- Function to insert data into the SQLite database
function M.insert(task)
    local env = luasql.sqlite3()
    local conn = env:connect("tasks.db")

    local insert_task_sql = string.format([[
        INSERT INTO tasks (filename, line_number, status, description)
        VALUES ('%s', %d, '%s', '%s');
    ]], task.filename, task.line_number, task.status, task.description)
    conn:execute(insert_task_sql)

    -- Get the last inserted task_id
    local cursor = conn:execute("SELECT last_insert_rowid()")
    local task_id = cursor:fetch()

    -- Insert tags
    for _, tag in ipairs(task.tags) do
        local insert_tag_sql = string.format("INSERT INTO tags (task_id, tag) VALUES (%d, '%s');", task_id, tag)
        conn:execute(insert_tag_sql)
    end

    -- Insert parameters
    for param_name, param_value in pairs(task) do
        if param_name ~= "filename" and param_name ~= "line_number" and param_name ~= "status" and param_name ~= "description" and param_name ~= "tags" then
            local insert_param_sql = string.format("INSERT INTO parameters (task_id, parameter_name, parameter_value) VALUES (%d, '%s', '%s');", task_id, param_name, param_value)
            conn:execute(insert_param_sql)
        end
    end
    -- Close the connection
    conn:close()
    env:close()
end

