
require('dev.lua.sqlite2')
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

function select_by_tag(tag)
    local fmt = string.format
    tag = tag or 1
    -- local query_tag = "select distinct t.id from tasks t left join tags tg ON t.id = tg.task_id where tg.tag = '#main'"
    -- local query_task = fmt('SELECT * FROM tasks WHERE id = %s;', tag)
    -- local query_tags = fmt('SELECT tag FROM tags WHERE task_id = %s;', tag)
 --    local query_params = fmt('SELECT name, value FROM parameters WHERE task_id = %d;', tag)
    local query = [[
    SELECT distinct t.*, p.name AS name, p.value AS value, tg.tag
    FROM tasks t
    LEFT JOIN parameters p ON t.id = p.task_id
    LEFT JOIN tags tg ON t.id = tg.task_id
    WHERE t.id IN (
        SELECT task_id FROM tags WHERE tag = '#main'
    );
]]
    local db = '/home/gagarin/sync/obsidian/tasks.db'
    local sql = Sql(db)
    sql:connect()
    -- print('query_task:', query_task)
    -- print('query_tags:', query_tags)
    -- print('query_params:', query_params)
    local tasks = {}
    local raw_tasks = sql:query_n(query)
    pprint(raw_tasks)
    for _,rtask in ipairs(raw_tasks) do
        local task_id = rtask.id

        -- If this task_id is not already in the tasks table, initialize it
        if not tasks[task_id] then
            tasks[task_id] = {
                id = task_id,
                filename = rtask.filename,
                line_number = rtask.line_number,
                status = rtask.status,
                description = rtask.description,
                parameters = {},
                tags = {}
            }
        end

        -- Add the parameter if it exists and is not already added
        if rtask.name and rtask.value then
            tasks[task_id].parameters[rtask.name] = rtask.value
        end

        -- Add the tag if it exists and is not already added
        if rtask.tag and not tasks[task_id].tags[rtask.tag] then
            table.insert(tasks[task_id].tags, rtask.tag)
        end
    end
    -- local params = sql:query_n(query_params)
    -- local tags = sql:query_n(query_tags)
    sql:close()
    -- for _, task in ipairs(tasks) do
    --     pprint(task)
    -- end
    print('tasks:')
    pprint(tasks)

    return tasks
end
