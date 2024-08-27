-- TODO create a private members table to be automatically detected by the __index metamethod
function class(type, func_handle_args, ...)
    local mt = {}
    local argv = {...}
    argv=argv[1]
    mt.__call = function(Type, ...)
        local obj = {}
        local metamt = {}
        for k, v in pairs(Type) do
            if k ~= "__index" then
                metamt[k] = v
            end
        end

        setmetatable(obj, {__index = metamt})
        if func_handle_args then
            obj = func_handle_args(obj, ...)
            if obj == nil then
                error("Error: function to handle constructor arguments must return self object (returned nil)")
            end
        end
        if argv then
            for k, v in pairs(argv) do
                if k ~= "__index" then
                    obj[k] = v
                end
            end
        end
        return  obj
    end
    type = setmetatable(type, mt)
    return type
end

return true

