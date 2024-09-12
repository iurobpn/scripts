#!/usr/bin/fish


# cat err.log
# cat err.log | sed -e 's/lua\(jit\)*: //' | sed -n '/.*:[0-9]\+:.*/{p}' | sed  -e 's/^[[:space:]]*//' | sed -e 's/^\.\///'

cat $argv | sed -e 's/lua\(jit\)*: //'   -e 's/^[[:space:]]*//' -e 's/^\.\///' | grep -e '\.lua:[0-9]\+:' -e 's/^Error[a-zA-Z ]\+: *\(.*:[0-9]\+:.*\)$/\1/' > /tmp/error_lua2.log
