#!/usr/bin/fish


# cat err.log
# cat err.log | sed -e 's/lua\(jit\)*: //' | sed -n '/.*:[0-9]\+:.*/{p}' | sed  -e 's/^[[:space:]]*//' | sed -e 's/^\.\///'

lua $argv[1] 2>&1 | sed -e 's/lua\(jit\)*: //'  -e 's/^[[:space:]]*//' -e 's/^\.\///' | grep -e '\.lua:[0-9]\+:' > /tmp/error_lua.log
cat /tmp/error_lua.log
