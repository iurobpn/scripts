local M = {}
local fzf_lua = require('fzf-lua')
-- Function to format the tasks into a string
function M.format_task(task)
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
-- -- QUERIES
-- SELECT t.id
-- FROM task t
-- JOIN parameters p ON t.id = p.task_id
-- JOIN tags tg ON t.id = tg.task_id
-- WHERE tg.tag = '#research'  -- Filter by the tag
--   AND p.key = 'due_date'    -- Ensure the task has a 'due_date' key
-- ORDER BY p.value ASC;       -- Sort by 'due_date'

-- Function to feed tasks to fzf-lua grep-like search with markdown syntax highlighting
function M.search_tasks(TaskList)
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
    },
    -- On opening the fzf-lua window, set markdown syntax highlighting
    winopts = {
      preview = {
        syntax = 'markdown', -- Set markdown syntax for the preview window
      }
    }
  })
end

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

-- Function to format tasks for display
function M.format_task(task)
  local task_line = string.format("%s:%d: %s", task.file, task.line, task.description)

  -- Add tags and parameters to the task description
  if #task.tags > 0 then
    task_line = task_line .. " " .. table.concat(task.tags, " ")
  end

  if next(task.parameters) ~= nil then
    for key, value in pairs(task.parameters) do
      task_line = task_line .. string.format(" [%s:: %s]", key, value)
    end
  end

  return task_line
end

-- Function to prompt for refining the search
function M.prompt_refine_search(selected_tasks)
  -- Prompt the user with a confirmation
  local answer = vim.fn.input("Refine search on selected tasks? (y/n): ")
  if answer:lower() == 'y' then
    -- Perform the refined search on the selected tasks
    refined_search(selected_tasks)
  else
    print("Search completed.")
  end
end

-- Function to perform the initial search
function M.initial_search()
  -- Prepare the task lines
  local task_lines = {}
  for _, task in ipairs(TaskList) do
    table.insert(task_lines, format_task(task))
  end

  -- Perform the fzf search
  fzf_lua.fzf_exec(task_lines, {
    prompt = 'Search Tasks> ',
    multi = true,  -- Allow multiple selections
    actions = {
      -- On selecting tasks, ask if the user wants to refine the search
      ["default"] = function(selected)
        -- Capture the selected tasks
        local selected_tasks = {}
        for _, task_line in ipairs(selected) do
          -- Extract file and line information (and other data)
          table.insert(selected_tasks, task_line)
        end

        -- Prompt for refining the search on the selected tasks
        prompt_refine_search(selected_tasks)
      end
    }
  })
end

-- Function to perform a refined search on selected tasks
function M.refined_search(selected_tasks)
  -- Perform another fzf search on the selected tasks
  fzf_lua.fzf_exec(selected_tasks, {
    prompt = 'Refined Search> ',
    multi = true,  -- Allow further multiple selections if needed
    actions = {
      -- Handle refined selection or other actions
      ["default"] = function(final_selection)
        for _, task_line in ipairs(final_selection) do
          print("Final selected task:", task_line)
        end
      end
    }
  })
end

-- Example usage: Start the initial search
-- initial_search()

return M
