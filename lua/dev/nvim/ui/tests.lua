
function test_window()
    local win = Window()
    win.width = 0.5
    win.height = 0.5
    win.row = 0.5
    win.col = 0.5
    win:open()
    win:params()
end

function test_popup()
    local win = Window.popup({content='hello'})
    win:open()
    win:params()
end

function popup(...)
    local buf = vim.api.nvim_create_buf(false, true)  -- false for listed, true for scratch

    local ui_width = vim.api.nvim_get_option("columns")
    local ui_height = vim.api.nvim_get_option("lines")
    local opts = {
        relative = 'editor',
        width = 8,
        height = 3,
        row = math.floor((ui_height - 8) / 2),
        col = math.floor((ui_width - 3) / 2),
        style = 'minimal',
        border = 'rounded',
        modifiable = false,
        buffer = {
            listed = false,
            scratch = true,
        },
    }
    for k, v in pairs(arg) do
        opts[k] = v
    end

    local win = vim.api.nvim_open_win(buf, true, opts)
end

function layout_popup()
    local Popup = require("nui.popup")
    local Layout = require("nui.layout")

    local popup_one, popup_two = Popup({
        enter = true,
        border = "single",
    }), Popup({
        border = "double",
    })

    local layout = Layout(
        {
            position = "50%",
            size = {
                width = 80,
                height = "60%",
            },
        },
        Layout.Box({
            Layout.Box(popup_one, { size = "40%" }),
            Layout.Box(popup_two, { size = "60%" }),
        }, { dir = "row" })
    )

    local current_dir = "row"

    popup_one:map("n", "r", function()
        if current_dir == "col" then
            layout:update(Layout.Box({
                Layout.Box(popup_one, { size = "40%" }),
                Layout.Box(popup_two, { size = "60%" }),
            }, { dir = "row" }))

            current_dir = "row"
        else
            layout:update(Layout.Box({
                Layout.Box(popup_two, { size = "60%" }),
                Layout.Box(popup_one, { size = "40%" }),
            }, { dir = "col" }))

            current_dir = "col"
        end
    end, {})

    layout:mount()
end
