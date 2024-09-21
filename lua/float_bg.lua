-- Define a custom highlight group for floating window background
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = "#282c34", fg = "#bbc2cf" })  -- Set background and foreground colors

-- Optionally, define a custom border highlight group for the floating window border
vim.api.nvim_set_hl(0, 'FloatBorder', { bg = "#282c34", fg = "#51afef" })  -- Customize border colors


-- Define floating window configuration
local opts = {
  relative = 'editor',
  width = 40,
  height = 10,
  row = 3,
  col = 10,
  style = 'minimal',
  border = 'single'  -- Use a border ('single', 'double', etc.), or remove this option for no border
}

-- Create a floating window
local buf = vim.api.nvim_create_buf(false, true)  -- Create a new empty buffer
vim.api.nvim_open_win(buf, true, opts)  -- Open the floating window with custom options

-- Define a second custom highlight group
vim.api.nvim_set_hl(0, 'CustomFloatHighlight', { bg = "#3c3836", fg = "#ebdbb2" })

-- Apply the new highlight for a different floating window
-- Example with `CustomFloatHighlight`:
vim.api.nvim_set_hl(0, 'NormalFloat', { link = 'CustomFloatHighlight' })
