local utils = require('utils')
local json = require('cjson')
local list = require('dev.lua.list')

local M = {}

M.remove = function(tbl, key)
    for k, _ in pairs(tbl) do
        if k == key then
            tbl[k] = nil
            break
        end
    end
end

M.contains = function(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end


M.extend = function(tbl1, tbl2)
    for k,v in pairs(tbl2) do
        tbl1[k] = v
    end
    return tbl1
end

M.flatten = function(tbl, d)
    if d == nil then
        d = 5
    end
    if d == 0 then
        return tbl
    end
    local res = {}
    for _, v in pairs(tbl) do
        if type(v) == 'table' then
            local inner = M.flatten(v, d-1)
            res = list.extend(res, inner)
        else
            table.insert(res, v)
        end
    end

    return res
end

M.merge = function(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == 'table' then
            if type(t1[k] or false) == 'table' then
                M.merge(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
end


M.to_json = function(tbl)
    local out = {}

    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            out[k] = M.to_json(v)
        else
            if not utils.is_callable(k) and not utils.is_callable(v) then
                out[k] = v
            end
        end
    end

    return json.encode(out)
end

M.deepcopy = function(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            copy[k] = M.deepcopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

return M

