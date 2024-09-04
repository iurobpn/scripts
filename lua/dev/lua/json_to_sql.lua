require('class')
local json = require("dkjson")
require('dev.lua.sqlite')
local luasql = require("luasql.sqlite3")

local parser = require('dev.lua.tasks.parser')

local M = { 
    filename = 'tasks.db',
    path = '/home/gagarin/sync/obsidian/',
    sql = nil,
}

function M:create_table()
    -- Connect to (or create) the SQLite database
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
    self.sql:run(create_table_sql)
end

M = class(M, {constructor = function(self, filename)
    if filename ~= nil then
        self.filename = filename
    end
    self.sql = Sql(self.filename)
    return self
end})

-- Function to insert data into the SQLite database
function M:insert(task)
    print_table(task)
    local insert_task_sql = string.format([[
        INSERT INTO tasks (filename, line_number, status, description)
        VALUES ('%s', %d, '%s', '%s');
    ]], task.filename, task.line_number, task.status, task.description)

    if not self.sql.connected then
        print('Not connected to the database')
        return
    end
    self.sql:run(insert_task_sql)

    -- Get the last inserted task_id
    local task_id = self.sql:query("SELECT last_insert_rowid()")

    -- Insert tags
    for _, tag in ipairs(task.tags) do
        local insert_tag_sql = string.format("INSERT INTO tags (task_id, tag) VALUES (%d, '%s');", task_id, tag)
        self.sql:run(insert_tag_sql)
    end

    -- Insert parameters
    for param_name, param_value in pairs(task) do
        if param_name ~= "filename" and param_name ~= "line_number" and param_name ~= "status" and param_name ~= "description" and param_name ~= "tags" then
            local insert_param_sql = string.format("INSERT INTO parameters (task_id, parameter_name, parameter_value) VALUES (%d, '%s', '%s');", task_id, param_name, param_value)
            self.sql:run(insert_param_sql)
        end
    end
end

local function get_command_output(cmd)
    -- Execute the Fish shell command and capture the output
    local handle = io.popen(cmd)
    if not handle then
        print("Failed to execute command: " .. cmd)
        return nil
    end
    local result = handle:read("*a")
    handle:close()
    
    -- Return the output, trimming any trailing newlines
    return result --:gsub("%s+$", "")
end

-- Example usage
-- local output = get_command_output("fish -c 'echo Hello from Fish!'")
-- read and parse tasks from the notes to a lua table
-- @param folder: folder with the notes
-- @return: a table of tasks
function M:read_notes(folder)
    if folder ~= nil and folder ~='' then
        self.path = folder
    end
    local raw_tasks = get_command_output("fish -c 'find_tasks.fish --dir=" .. self.path .. "'")
    self.sql:set_path(self.path)
    if raw_tasks == nil then
        print('find_tasks returned nil')
        return
    end
    require'utils'
    raw_tasks  = split(raw_tasks, '\n')
    if raw_tasks == nil then
        print('splitted tasks are nil')
        return
    end

    self.sql:connect()
    self:create_table()

    -- inspect(raw_tasks)
    for _, line in ipairs(raw_tasks) do
        print_table(line)
        local task = parser.parse(line)
        if task == nil then
            print('parser failed to parse the task')
        else
            self:insert(task)
        end
    end
    self.sql:close()
end


function M.select_tasks()
    local query = 'SELECT * FROM tasks;'
    local query2 = 'SELECT tag FROM tags WHERE task_id = 1;'
    local query3 = 'SELECT parameter_name, parameter_value FROM parameters WHERE task_id = 1;'
end

function M.tosql()
    local j2s = M()
    j2s:read_notes()
end

return M


