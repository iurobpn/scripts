local inspect = require'inspect'.inspect;

local t1 = {1, 2, 3}

local mt2 = getmetatable(t)
mt2 = {}
mt2.__index = function(t, k)
    print('mt: index', k)
    return nil
end

setmetatable(t1, mt2)

print(inspect(t1))
local a = t1[4]

if a == nil then
    print('a is nil')
else
    print('a is not nil', a)
end

local sql = require'dev.lua.sqlite2'
local Sql = sql.Sql

print('Sql table: ' .. inspect(Sql))

local s1 = Sql()
local s2 = Sql()

print('s1 table: ' .. inspect(s1))
print('s2 table: ' .. inspect(s2))
