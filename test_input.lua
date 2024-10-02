
-- Define your table of words
local words = { "apple", "banana", "cherry", "date", "elderberry", "fig", "grape" }

-- Define the completion function
local function word_completion(arg_lead, cmd_line, cursor_pos)
  local matches = {}
  for _, word in ipairs(words) do
    if word:sub(1, #arg_lead) == arg_lead then
      table.insert(matches, word)
    end
  end
  return matches
end

-- Use vim.fn.input with the completion function
local user_input = vim.fn.input("Enter a fruit: ", "", word_completion)
print("You selected: " .. user_input)

