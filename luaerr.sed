sed -e 's/lua\(jit\)*: //'
sed -n '/.*:[0-9]\+:.*/{p}'
sed -e 's/^[[:space:]]*//'
sed -e 's/^\.\///'
