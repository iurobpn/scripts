
-- Define namespace for extmarks
local ns_id = vim.api.nvim_create_namespace('my_namespace')

-- Enable conceallevel in buffer
vim.api.nvim_set_option_value('conceallevel', 2, {buf = 0})

-- Set virtual text inline, shifting original line content
vim.api.nvim_buf_set_extmark(0, ns_id, 1, 0, {
  virt_text = { { "Virtual Text", "MyVirtualText" } },  -- Use your custom highlight group
  virt_text_pos = "inline",  -- Prepend virtual text
})

-- Define conceal syntax in VimL to hide the word "hide"
vim.cmd("syntax match ConcealExample 'Author' conceal")
