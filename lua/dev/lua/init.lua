-- submodules of dev.lua
-- require'utils.lua' -- empty

local lua = {
    proj = require'dev.lua.project',
}
vim.g.proj = lua.proj
vim.g.proj.init()

lua.sqlite    = require'dev.lua.sqlite'
lua.tasks     = require'dev.lua.tasks'
lua.fs        = require'dev.lua.fs'
lua.log       = require'dev.lua.log'
lua.zotero    = require'dev.lua.zotero'
lua.templater = require'dev.lua.templater'
-- require'dev.lua.float'
-- require'dev.lua.qfloat'
-- init()
-- require'float.lua' --not properly tested
return lua
