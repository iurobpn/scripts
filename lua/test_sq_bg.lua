-- Gruvbox color values
local colors = {
    dark0_hard = '#1d2021',
    dark3 = '#665c54',
}

-- Create a new namespace
local ns_id = vim.api.nvim_create_namespace('custom_window_bg')

-- Define padding
local top_padding = 5
local bottom_padding = 5
local left_padding = 5
local right_padding = 5

-- Get the current buffer
local bufnr = vim.api.nvim_get_current_buf()

-- Function to update the rectangle highlights
local function update_rectangle_highlight()
    -- Recalculate window dimensions
    local win_width = vim.api.nvim_win_get_width(0)
    local win_height = vim.api.nvim_win_get_height(0)

    -- Recalculate rectangle boundaries
    local rect_top = top_padding
    local rect_bottom = win_height - bottom_padding - 1
    local rect_left = left_padding
    local rect_right = win_width - right_padding - 1

    -- Clear previous highlights in the namespace
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

    -- Reapply the 'Normal' highlight to the window
    vim.api.nvim_set_hl(ns_id, 'Normal', { bg = colors.dark0_hard })
    vim.api.nvim_win_set_hl_ns(0, ns_id)

    -- Define 'MiddleRectangle' highlight group
    vim.api.nvim_set_hl(ns_id, 'MiddleRectangle', { bg = colors.dark3 })

    -- Apply the 'MiddleRectangle' highlight to the rectangle region
    for line = rect_top, rect_bottom do
        vim.api.nvim_buf_add_highlight(bufnr, ns_id, 'MiddleRectangle', line, rect_left, rect_right + 1)
    end
end

-- Initial call to set up the highlights
update_rectangle_highlight()

-- Set up autocommand to trigger on window resize
vim.api.nvim_create_autocmd({ "VimResized", "WinScrolled", "WinResized" }, {
    callback = function()
        update_rectangle_highlight()
    end,
})
