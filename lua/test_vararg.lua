
local function print_table(t)
    print('print_table')
    for k,v in pairs(t) do
        print(k,v)
    end
end

local function foo(...)
    print('foo')
    for i,v in ipairs(arg) do
        print(i,v)
    end
    return arg
end
local c = foo(1, 2, 3, {})
print('\n')
print_table(c)

local call = function(self, ...)
    print('c.__call')
    for i,v in ipairs(arg) do
        print(i,v)
    end
    return arg
end
mt = getmetatable(c)
mt = mt or {}
mt.__call = call
setmetatable(c, mt)
c()
