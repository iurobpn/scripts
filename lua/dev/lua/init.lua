-- submodules of dev.lua
-- require'utils.lua' -- empty

local lua = {
    sqlite = require'dev.lua.sqlite2',
    tasks = require'dev.lua.tasks',
    fs = require'dev.lua.fs',
    log = require'dev.lua.log',
    proj = require'dev.lua.project',
    zotero = require'dev.lua.zotero',
}

vim.g.proj = lua.proj

vim.g.proj.init()
-- require'dev.lua.float'
-- require'dev.lua.qfloat'
-- init()
-- require'float.lua' --not properly tested
return lua
