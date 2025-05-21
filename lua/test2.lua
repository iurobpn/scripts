require'class'
-- require'dev.lua.log'    
I = require'inspect'

Foo = {
    name = 'asd',
    idade = 10
}
Foo = _G.class(Foo)


foo =Foo()
print('foo: ' .. I.inspect(foo))
foo.name = 'asd'
print('foo: ' .. I.inspect(foo))
