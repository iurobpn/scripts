
-- list all tables
-- SELECT name FROM sqlite_master WHERE type='table';

-- list columns of a specific table
-- PRAGMA table_info('table_name');

-- PRAGMA database_list;
--
require('dev.lua.sqlite')
local home = os.getenv('HOME')
local M = {
    filename = 'zotero.sqlite',
    path = home .. '/sync/zotero/',
    sql = nil,
}


-- Connect to (or create) the SQLite databas

-- Function to get all table names
function M:get_table_names()
    local tables = self.sql:query_n("SELECT name FROM sqlite_master WHERE type='table';")
    return tables
end

-- Function to get column info for a given table
function M:get_table_columns(table_name)
    local columns = self.sql:query_n(string.format("PRAGMA table_info('%s');", table_name))
    return columns
end

-- Function to inspect the database structure
function M:inspect_database()
    self.sql:connect()
    local tables = self:get_table_names()
    for _, table_name in ipairs(tables) do
        print("Table:", table_name)
        local columns = self:get_table_columns(table_name)
        for _, col in ipairs(columns) do
            print(string.format("  Column: %s, Type: %s, Primary Key: %s, Not Null: %s, Default: %s",
                col.name, col.type, tostring(col.pk), tostring(col.notnull), col.dflt_value or "NULL"))
        end
    end
    self.sql:close()
end
local Module = {
    Zotero = M
}

M = class(M, {constructor = function(self, filename, path)
    if filename ~= nil then
        self.filename = filename
    end
    self.sql = Sql(self.filename)
    self.sql:set_path(path)

    return self
end})

-- Inspect the database
-- inspect_database()
return Module
