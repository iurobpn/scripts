-- submodules of dev.lua
-- require'utils.lua' -- empty
require'dev.lua.utils'
require'dev.lua.fs'
require'dev.lua.log'

vim.g.proj = require'dev.lua.project'

vim.g.proj.init()
-- require'dev.lua.float'
-- require'dev.lua.qfloat'
-- init()
-- require'float.lua' --not properly tested
