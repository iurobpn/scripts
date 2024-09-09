local fzf_lua = require('fzf-lua')

-- Example TaskList format
local TaskList = {
  {
    id = 1,
    file = "/path/to/file1.md",
    line = 10,
    description = "Complete the report",
    parameters = { priority = "high", due = "tomorrow" },
    tags = { "#work", "#report" },
  },
  {
    id = 2,
    file = "/path/to/file2.md",
    line = 15,
    description = "Fix the bug in module",
    parameters = { priority = "urgent" },
    tags = { "#bugfix", "#urgent" },
  }
}

-- Function to format the tasks into a string
local function format_task(task)
  -- Create the file:line format
  local task_line = string.format("%s:%d: - [ ] %s", task.file, task.line, task.description)

  -- Add tags
  if #task.tags > 0 then
    task_line = task_line .. " " .. table.concat(task.tags, " ")
  end

  -- Add parameters (metatags)
  if next(task.parameters) ~= nil then
    for key, value in pairs(task.parameters) do
      task_line = task_line .. string.format(" [%s:: %s]", key, value)
    end
  end

  return task_line
end

-- Function to feed tasks to fzf-lua grep-like search
local function search_tasks()
  -- Prepare the list of tasks in a grep-like format
  local task_lines = {}
  for _, task in ipairs(TaskList) do
    table.insert(task_lines, format_task(task))
  end

  -- Feed the task lines to fzf-lua
  fzf_lua.fzf_exec(task_lines, {
    prompt = 'Search Tasks> ',
    -- Define actions when a task is selected
    actions = {
      -- On selection, go to the file and line of the selected task
      ["default"] = function(selected)
        local path, line = selected[1]:match("([^:]+):(%d+)")
        if path and line then
          vim.cmd(string.format("edit %s", path))
          vim.fn.cursor(tonumber(line), 1)
        end
      end
    }
  })
end

-- Example usage: Call this function to start searching tasks
search_tasks()
