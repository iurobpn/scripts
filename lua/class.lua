-- TODO create a private members table to be automatically detected by the __index metamethod

--- class generator
---@param t table
---@param ... any
---@return table
function _G.class2(t, ...)
    local proto = {}
    for k, v in pairs(t) do
        if k == 'new' then
            proto.__call = v
        end
        proto[k] = v
    end
    local args = {...}
    args = args[1] or {}

    for k, v in pairs(args) do
        if k == 'constructor' then
            proto.__call = v
        else
            proto[k] = v
        end
    end

    local mt = getmetatable(t) or {}

    setmetatable(proto, mt)

    if proto.__call == nil then
        proto.__call = function()
            local obj = {}
            setmetatable(obj,t)
            return obj
        end
    end

    setmetatable(t,proto)

    return t
end

--- class generator
---@param t table
---@param ... any
---@return table
function _G.class(t, opts)
    t = t or {}
    for k, v in pairs(t) do
        if k == 'new' then
            t.__call = v
        end
    end
    
    opts = opts or {}
    for k, v in pairs(opts) do
        if k == 'constructor' or k == 'new' then
            t.__call = v
        else
            t[k] = v
        end
    end

    t.__index = t

    if t.__call == nil then
        t.__call = function(obj)
            obj = obj or {}
            setmetatable(obj,t)
            return obj
        end
    end

    setmetatable(t, t)

    return t
end

return true

