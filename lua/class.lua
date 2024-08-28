-- TODO create a private members table to be automatically detected by the __index metamethod


function class(type, ...) -- args have to be put inside a table
    local mt = {}
    local argv = {...}
    -- if not vim then 
    argv = argv[1]
    mt.__call = function(Type, ...)
        local obj = {}

        setmetatable(obj, {__index = Type})
        if argv ~= nil and argv['constructor'] then
            local f = argv['constructor']
            obj = f(obj, ...)
        else
            obj = handle_args(obj, ...)
        end
        if obj == nil then
            error("Error: function to handle constructor arguments must return self object (returned nil)")
        end
        return  obj
    end
    type = setmetatable(type, mt)
    return type
end


function handle_args(obj, ...)
    local argv = {...}
    argv = argv[1]
    if argv then
        for k, v in pairs(argv) do
            if k ~= "__index" then
                obj[k] = v
            end
        end
    end
    return obj
end

return true

