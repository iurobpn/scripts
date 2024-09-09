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

return M
