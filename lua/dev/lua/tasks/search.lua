
function select_by_id(id)
    local fmt = string.format
    id = id or 1
    local query_task = fmt('SELECT * FROM tasks WHERE id = %d;', id)
    local query_tags = fmt('SELECT tag FROM tags WHERE task_id = %d;', id)
    local query_params = fmt('SELECT name, value FROM parameters WHERE task_id = %d;', id)
    -- local query = 'SELECT tag FROM tags WHERE task_id = 1;'
    -- local query = 'SELECT * FROM tasks;'
    -- local query2 = 'SELECT * FROM tasks WHERE task_id = 1;'
    -- local query3 = 'SELECT parameter_name, parameter_value FROM parameters WHERE task_id = 1;'
    local db = '/home/gagarin/sync/obsidian/tasks.db'
    local sql = Sql(db)
    sql:connect()
    -- print('query_task:', query_task)
    -- print('query_tags:', query_tags)
    -- print('query_params:', query_params)
    local task = sql:query_n(query_task)
    local params = sql:query_n(query_params)
    local tags = sql:query_n(query_tags)
    sql:close()
    task = task[1]
    task.parameters = {}
    for i, p in ipairs(params) do
        task.parameters[p.name] = p.value
    end
    task.tags = {}
    for i, tag in ipairs(tags) do
        table.insert(task.tags, tag.tag)
    end

    return task
end
