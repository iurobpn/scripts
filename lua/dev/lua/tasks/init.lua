local M = {
    query = require('dev.lua.tasks.query'),
    parser = require('dev.lua.tasks.parser'),
    Indexer = require('dev.lua.tasks.indexer').Indexer,
    fzf = require('dev.lua.tasks.fzf'),
    views = require('dev.lua.tasks.views'),
}

return M
