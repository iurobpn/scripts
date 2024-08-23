
-- Get the current Neovim UI size
local ui_width = vim.api.nvim_get_option("columns")
local ui_height = vim.api.nvim_get_option("lines")

-- Set the size of the floating window
local win_width = math.ceil(ui_width * 0.6)  -- 60% of the screen width
local win_height = math.ceil(ui_height * 0.6)  -- 60% of the screen height

-- Calculate the starting position of the floating window
local row = math.ceil((ui_height - win_height) / 2)
local col = math.ceil((ui_width - win_width) / 2)

-- Create a new buffer
local buf = vim.api.nvim_create_buf(false, true)  -- false for listed, true for scratch

-- Define window options
local opts = {
  style = "minimal",
  relative = "editor",
  row = row,
  col = col,
  width = win_width,
  height = win_height,
  border = "single"
}

-- Open the floating window
local win = vim.api.nvim_open_win(buf, true, opts)


vim.api.nvim_buf_set_name(buf, "path/to/file.txt")
vim.api.nvim_command("edit")  -- or 'e' for short

local content = {
    "This is the first line",
    "This is the second line",
    "And so on..."
}
vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

vim.api.nvim_win_close(win, true)  -- true indicates force close


-- generate links in file:number
-- Create a buffer with example links
local function setup_buffer_with_links()
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Example list of files with line numbers
  local lines = {
    "example.lua:10",
    "another_file.lua:20",
    "yet_another.lua:30"
  }

  -- Set the buffer lines
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Define a pattern to match 'filename.lua:number'
  local pattern = [[\v(\S+\.lua):(\d+)]]

  -- Highlight the matching pattern
  vim.fn.matchadd("Underlined", pattern)

  -- Set the buffer as the current buffer
  vim.api.nvim_set_current_buf(buf)

  -- Set an autocmd to handle opening files when the link is selected
  vim.api.nvim_exec([[
    augroup FileLinkHandler
      autocmd!
      autocmd CursorMoved <buffer> lua handle_link()
    augroup END
  ]], false)

  return buf
end


-- Open the buffer with links
local function open_in_floating_window(filename, line)
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Set the buffer name to the filename
  vim.api.nvim_buf_set_name(buf, filename)

  -- Load the file content into the buffer
  vim.api.nvim_command("edit " .. filename)

  -- Get the current UI size
  local ui_width = vim.api.nvim_get_option("columns")
  local ui_height = vim.api.nvim_get_option("lines")

  -- Set the floating window size and position
  local win_width = math.ceil(ui_width * 0.8)
  local win_height = math.ceil(ui_height * 0.8)
  local row = math.ceil((ui_height - win_height) / 2)
  local col = math.ceil((ui_width - win_width) / 2)

  -- Define the window options
  local opts = {
    style = "minimal",
    relative = "editor",
    row = row,
    col = col,
    width = win_width,
    height = win_height,
    border = "single"
  }

  -- Open the floating window
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Move to the specific line
  vim.api.nvim_win_set_cursor(win, {line, 0})
end

local function handle_link()
  -- Get the current line content
  local line = vim.api.nvim_get_current_line()

  -- Match the pattern 'filename.lua:number'
  local pattern = "([^:]+):(%d+)"
  local filename, line_number = string.match(line, pattern)

  if filename and line_number then
    -- Make the link clickable
    vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', '', {
      noremap = true,
      silent = true,
      callback = function()
        open_in_floating_window(filename, tonumber(line_number))
      end
    })
  end
end
-- ag  '\- \[.\]' | cut -d : -f1,2 | sed 's/:/ /g'                                                                                                                   22.3.0 󰌠 3.12.4 (python3.12)

--setup the buffer with links and test
setup_buffer_with_links()''
