function get_patterns()
    local lpeg = require("lpeg")
    local P, R, C, S = lpeg.P, lpeg.R, lpeg.C, lpeg.S
    local digit = R('09')
    local sep = P('-')
    hex = R('09', 'af', 'AF')^1
    name = (R('az', 'AZ', '09') + S('-_'))^1
    date = digit^4+sep + digit^2+sep + digit^2
    time = digit^2 + P(':') + digit^2
    uuid = hex^1 + sep + hex^1 + sep + hex^1 + sep + hex^1
    local mtag =
      P("[") * C(name) * P(":: ") * C(date) * P("]")
    local atuuid = P("@{") * C(uuid) * P("}")
    return mtag, atuuid
end

local mtag, atuuid = get_patterns()

s = "@{12345678-1234-1234-1234-1234567890ab}"
print("atuuid: ", atuuid:match(s))
s = "[test:: 2023-10-01]"
print("mtag: ", mtag:match(s))

