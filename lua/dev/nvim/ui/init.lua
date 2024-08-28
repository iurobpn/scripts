require('dev.nvim.ui.float')
require('dev.nvim.ui.qfloat')
require('dev.nvim.ui.clock')
require('dev.nvim.ui.window')

print('nvim.ui module loaded')



function init()
    Clock.open()
end

init()
