local presets = require('cmake-tools.presets')

local ps = presets.parse('/home/gagarin/git/nmpc-obs/cpp/CMakePresets.json')
print(vim.inspect(ps))
