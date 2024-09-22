-- Create a new highlight namespace
local ns_id = vim.api.nvim_create_namespace('window_bg')

-- Define custom highlights within this namespace
vim.api.nvim_set_hl(ns_id, 'Normal', { bg = '#1E1E2E', fg = '#C0CAF5' })  -- Set background and foreground colors
vim.api.nvim_set_hl(ns_id, 'CursorLine', { bg = '#2A2A3A' })              -- Customize cursor line background
vim.api.nvim_set_hl(ns_id, 'LineNr', { fg = '#737AA2' })                  -- Customize line number color

-- Apply the namespace to the current window
vim.api.nvim_win_set_hl_ns(0, ns_id)

