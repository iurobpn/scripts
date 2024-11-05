local Input = require("nui.input")
local event = require("nui.utils.autocmd").event

local popup_options = {
    relative = "cursor",
    position = {
        row = 1,
        col = 0,
    },
    size = 20,
    border = {
        style = "rounded",
        text = {
            top = "[Input]",
            top_align = "left",
        },
    },
    win_options = {
        winhighlight = "Normal:Normal",
    },
}

local input = Input(popup_options, {
    prompt = "> ",
    default_value = "42",
    on_close = function()
        print("Input closed!")
    end,
    on_submit = function(value)
        print("Value submitted: ", value)
    end,
    on_change = function(value)
        print("Value changed: ", value)
    end,
})
input:mount()
