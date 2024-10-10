-- timer_plugin.lua
local timer_plugin = {}

-- Dependencies
local json = vim.fn.json_encode and vim.fn.json_decode and true or false
if not json then
    error("This plugin requires Neovim with JSON support (version 0.5 or higher).")
end

-- Data structures
local tasks = {}
local projects = {}
local active_tasks = {}
local done_tasks = {}
local logs = {}

local task_id_counter = 0
local project_id_counter = 0

local current_task = nil
local timer = nil
local timer_start_time = nil
local timer_active = false
local popup_win = nil

-- File paths for data persistence
local data_dir = vim.fn.stdpath('data') .. '/timer_plugin'
local tasks_file = data_dir .. '/tasks.json'
local logs_file = data_dir .. '/logs.json'

-- Utility functions
local function get_next_task_id()
    task_id_counter = task_id_counter + 1
    return task_id_counter
end

local function get_next_project_id()
    project_id_counter = project_id_counter + 1
    return project_id_counter
end

local function format_time(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end

local function save_data()
    if not vim.fn.isdirectory(data_dir) then
        vim.fn.mkdir(data_dir, "p")
    end

    local tasks_data = {
        tasks = tasks,
        active_tasks = active_tasks,
        done_tasks = done_tasks,
        task_id_counter = task_id_counter,
    }
    local tasks_json = vim.fn.json_encode(tasks_data)
    local tasks_file_handle = io.open(tasks_file, "w")
    tasks_file_handle:write(tasks_json)
    tasks_file_handle:close()

    local logs_data = {
        logs = logs,
    }
    local logs_json = vim.fn.json_encode(logs_data)
    local logs_file_handle = io.open(logs_file, "w")
    logs_file_handle:write(logs_json)
    logs_file_handle:close()
end

local function load_data()
    if vim.fn.filereadable(tasks_file) == 1 then
        local tasks_file_handle = io.open(tasks_file, "r")
        local tasks_json = tasks_file_handle:read("*a")
        tasks_file_handle:close()
        local tasks_data = vim.fn.json_decode(tasks_json)
        tasks = tasks_data.tasks or {}
        active_tasks = tasks_data.active_tasks or {}
        done_tasks = tasks_data.done_tasks or {}
        task_id_counter = tasks_data.task_id_counter or 0
    end

    if vim.fn.filereadable(logs_file) == 1 then
        local logs_file_handle = io.open(logs_file, "r")
        local logs_json = logs_file_handle:read("*a")
        logs_file_handle:close()
        local logs_data = vim.fn.json_decode(logs_json)
        logs = logs_data.logs or {}
    end
end

-- Load data on startup
load_data()

-- Timer command handler
function timer_plugin.TimerCommand(args)
    local subcommand = args.fargs[1]
    if not subcommand then
        print("Usage: :Timer <start|pause|stop|toggle> [task_id]")
        return
    end

    if subcommand == 'start' then
        local task_id_str = args.fargs[2]
        if not task_id_str then
            print("Usage: :Timer start <task_id>")
            return
        end
        local task_id = tonumber(task_id_str)
        timer_plugin.TimerStart(task_id)
    elseif subcommand == 'pause' then
        timer_plugin.TimerPause()
    elseif subcommand == 'stop' then
        timer_plugin.TimerStop()
    elseif subcommand == 'toggle' then
        timer_plugin.TimerToggle()
    else
        print("Invalid Timer command. Usage: :Timer <start|pause|stop|toggle> [task_id]")
    end
end

-- Timer functions
function timer_plugin.TimerStart(task_id)
    if not task_id or not tasks[task_id] then
        print("Invalid task ID.")
        return
    end

    if timer_active then
        print("A timer is already running.")
        return
    end

    current_task = tasks[task_id]
    timer_start_time = os.time()
    timer_active = true

    -- Start the timer
    timer = vim.loop.new_timer()
    timer:start(0, 1000, vim.schedule_wrap(function()
        timer_plugin.update_popup()
    end))

    -- Create popup window
    timer_plugin.create_popup()

    -- Log start time
    table.insert(logs, {
        task_id = task_id,
        task_name = current_task.name,
        time_start = timer_start_time,
        time_end = nil,
    })

    save_data()
    print("Timer started for task ID:", task_id)
end

function timer_plugin.TimerPause()
    if not timer_active then
        print("No active timer to pause.")
        return
    end

    local elapsed = os.time() - timer_start_time
    current_task.time_worked = (current_task.time_worked or 0) + elapsed
    timer:stop()
    timer:close()
    timer_active = false

    -- Update log
    for i = #logs, 1, -1 do
        if not logs[i].time_end then
            logs[i].time_end = os.time()
            break
        end
    end

    -- Close popup window
    timer_plugin.close_popup()

    save_data()
    print("Timer paused. Time worked:", format_time(current_task.time_worked))
end

function timer_plugin.TimerStop()
    if not timer_active then
        print("No active timer to stop.")
        return
    end
    timer_plugin.TimerPause()
    current_task = nil
    print("Timer stopped.")
end

function timer_plugin.TimerToggle()
    if popup_win and vim.api.nvim_win_is_valid(popup_win) then
        timer_plugin.close_popup()
    else
        timer_plugin.create_popup()
    end
end

-- Task command handler
function timer_plugin.TaskCommand(args)
    local subcommand = args.fargs[1]
    if not subcommand then
        print("Usage: :Task <new|list|del|done> [arguments]")
        return
    end

    if subcommand == 'new' then
        local name = args.fargs[2]
        if not name then
            print("Usage: :Task new <name>")
            return
        end
        timer_plugin.TaskNew(name)
    elseif subcommand == 'list' then
        timer_plugin.TaskList()
    elseif subcommand == 'del' then
        local task_id_str = args.fargs[2]
        if not task_id_str then
            print("Usage: :Task del <task_id>")
            return
        end
        local task_id = tonumber(task_id_str)
        timer_plugin.TaskDel(task_id)
    elseif subcommand == 'done' then
        local task_id_str = args.fargs[2]
        if not task_id_str then
            print("Usage: :Task done <task_id>")
            return
        end
        local task_id = tonumber(task_id_str)
        timer_plugin.TaskDone(task_id)
    else
        print("Invalid Task command. Usage: :Task <new|list|del|done> [arguments]")
    end
end

-- Task management functions
function timer_plugin.TaskNew(name)
    if name == "" then
        print("Task name cannot be empty.")
        return
    end

    local id = get_next_task_id()
    tasks[id] = {
        id = id,
        name = name,
        description = "",
        project_id = nil,
        start_time = nil,
        estimated_time = nil,
        time_worked = 0,
    }
    table.insert(active_tasks, id)
    save_data()
    print("Task created with ID:", id)
end

function timer_plugin.TaskList()
    print("Active Tasks:")
    for _, id in ipairs(active_tasks) do
        local task = tasks[id]
        print(string.format(
            "%d\t%s\t%s\t%s\t%s\t%s",
            task.id,
            task.name,
            task.description or "",
            task.start_time and os.date("%c", task.start_time) or "N/A",
            format_time(task.time_worked),
            task.estimated_time and format_time(task.estimated_time) or "N/A"
        ))
    end
    print("\nDone Tasks:")
    for _, id in ipairs(done_tasks) do
        local task = tasks[id]
        print(string.format(
            "%d\t%s\t%s\t%s\t%s\t%s",
            task.id,
            task.name,
            task.description or "",
            task.start_time and os.date("%c", task.start_time) or "N/A",
            format_time(task.time_worked),
            task.estimated_time and format_time(task.estimated_time) or "N/A"
        ))
    end
end

function timer_plugin.TaskDel(task_id)
    if not task_id or not tasks[task_id] then
        print("Invalid task ID.")
        return
    end

    if timer_active and current_task.id == task_id then
        timer_plugin.TimerStop()
    end

    tasks[task_id] = nil
    for i, id in ipairs(active_tasks) do
        if id == task_id then
            table.remove(active_tasks, i)
            break
        end
    end
    for i, id in ipairs(done_tasks) do
        if id == task_id then
            table.remove(done_tasks, i)
            break
        end
    end

    -- Remove related logs
    for i = #logs, 1, -1 do
        if logs[i].task_id == task_id then
            table.remove(logs, i)
        end
    end

    save_data()
    print("Task deleted:", task_id)
end

function timer_plugin.TaskDone(task_id)
    if not task_id or not tasks[task_id] then
        print("Invalid task ID.")
        return
    end

    local task = tasks[task_id]
    if timer_active and current_task.id == task_id then
        timer_plugin.TimerStop()
    end

    -- Compute final time worked
    if not task.time_worked then
        task.time_worked = 0
    end

    -- Move task to done_tasks
    for i, id in ipairs(active_tasks) do
        if id == task_id then
            table.remove(active_tasks, i)
            break
        end
    end
    table.insert(done_tasks, task_id)

    save_data()

    -- Display task
    print("Task marked as done:")
    print(string.format(
        "%d\t%s\t%s\t%s\t%s\t%s",
        task.id,
        task.name,
        task.description or "",
        task.start_time and os.date("%c", task.start_time) or "N/A",
        format_time(task.time_worked),
        task.estimated_time and format_time(task.estimated_time) or "N/A"
    ))
end

-- Popup window functions
function timer_plugin.create_popup()
    if popup_win and vim.api.nvim_win_is_valid(popup_win) then
        return
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('bufhidden', 'wipe', {buf = buf})

    local elapsed = os.time() - timer_start_time + (current_task.time_worked or 0)
    local time_str = format_time(elapsed)
    local content = { "Task: " .. current_task.name, "Time: " .. time_str }
    local width = 0
    for _, line in ipairs(content) do
        if #line > width then
            width = #line
        end
    end
    local height = #content
    local row = 0
    local col = vim.o.columns - width - 2

    popup_win = vim.api.nvim_open_win(buf, false, {
        relative = 'editor',
        width = width + 2,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'single',
    })

    timer_plugin.update_popup()
end

function timer_plugin.update_popup()
    if not popup_win or not vim.api.nvim_win_is_valid(popup_win) then
        return
    end

    local buf = vim.api.nvim_win_get_buf(popup_win)
    local elapsed = os.time() - timer_start_time + (current_task.time_worked or 0)
    local time_str = format_time(elapsed)
    local content = { "Task: " .. current_task.name, "Time: " .. time_str }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
end

function timer_plugin.close_popup()
    if popup_win and vim.api.nvim_win_is_valid(popup_win) then
        vim.api.nvim_win_close(popup_win, true)
        popup_win = nil
    end
end

-- Stats functions
function timer_plugin.ShowStats(args)
    local period = args.fargs[1]
    if not period then
        print("Usage: :Stats <daily|weekly|monthly>")
        return
    end

    local now = os.time()
    local start_time

    if period == 'daily' then
        start_time = os.time({ year = os.date("%Y"), month = os.date("%m"), day = os.date("%d"), hour = 0 })
    elseif period == 'weekly' then
        local day_of_week = os.date("*t").wday
        start_time = now - (day_of_week - 1) * 24 * 3600
    elseif period == 'monthly' then
        start_time = os.time({ year = os.date("%Y"), month = os.date("%m"), day = 1, hour = 0 })
    else
        print("Invalid period. Usage: :Stats <daily|weekly|monthly>")
        return
    end

    local total_time = 0
    local task_times = {}

    for _, log in ipairs(logs) do
        if log.time_end and log.time_start >= start_time then
            local duration = log.time_end - log.time_start
            total_time = total_time + duration
            task_times[log.task_id] = (task_times[log.task_id] or 0) + duration
        end
    end

    print(string.format("Total time worked (%s): %s", period, format_time(total_time)))

    print("Time spent per task:")
    for task_id, time_spent in pairs(task_times) do
        local task = tasks[task_id]
        if task then
            print(string.format("%d - %s: %s", task_id, task.name, format_time(time_spent)))
        end
    end
end

-- Command registrations
vim.api.nvim_create_user_command('Timer', function(args)
    timer_plugin.TimerCommand(args)
end, { nargs = '*' })

vim.api.nvim_create_user_command('Task', function(args)
    timer_plugin.TaskCommand(args)
end, { nargs = '*' })

vim.api.nvim_create_user_command('ShowLogs', function()
    timer_plugin.ShowLogs()
end, {})

vim.api.nvim_create_user_command('Stats', function(args)
    timer_plugin.ShowStats(args)
end, { nargs = 1 })

-- Function to display logs
function timer_plugin.ShowLogs()
    print("Timer Logs:")
    for _, log in ipairs(logs) do
        if log.time_end then
            local duration = log.time_end - log.time_start
            print(string.format(
                "%s - %s (%s) -- Task %d: %s",
                os.date("%c", log.time_start),
                os.date("%c", log.time_end),
                format_time(duration),
                log.task_id,
                log.task_name
            ))
        else
            print(string.format(
                "%s - (ongoing) -- Task %d: %s",
                os.date("%c", log.time_start),
                log.task_id,
                log.task_name
            ))
        end
    end
end

-- Ensure data is saved when Neovim exits
vim.api.nvim_create_autocmd("VimLeavePre", {
    pattern = "*",
    callback = function()
        save_data()
    end,
})

return timer_plugin
