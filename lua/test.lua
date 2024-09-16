-- Define the namespace for extmarks
local ns_id = vim.api.nvim_create_namespace('my_namespace')

-- Enable conceallevel in the buffer
-- vim.api.nvim_buf_set_option(0, 'conceallevel', 2)

-- Define a custom conceal highlight (optional, you can adjust if you want to use conceal symbols)
vim.api.nvim_set_hl(0, 'MyConceal', { fg = "NONE"})  -- Makes text invisible

-- Apply conceal to columns 5 to 10 on line 2 (1-based)
vim.api.nvim_buf_add_highlight(0, ns_id, 'MyConceal', 2, 5, 10)  -- Hide columns 5 to 10

-- Set virtual text at the beginning of the line (inline, moving original text to the right)
vim.api.nvim_buf_set_extmark(0, ns_id, 1, 0, {
  virt_text = { { "oi: ", "Comment" } },  -- Use your custom highlight group
  virt_text_pos = "inline",  -- Prepend virtual text inline, moving the original text to the right
})
