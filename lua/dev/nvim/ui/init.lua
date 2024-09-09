local ui = {
    float = require('dev.nvim.ui.float'),
    qfloat = require('dev.nvim.ui.qfloat'),
    views = require('dev.nvim.ui.views'),
}
ui.views.clock = require('dev.nvim.ui.clock')

function ui.init()
    ui.views.clock.open()
end

ui.init()

return ui
