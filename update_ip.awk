#!/bin/awk -f

FNR == NR {
    if ($0 ~ /([0-9]+\.){3}[0-9]+/) {
        ip = $0
    }
    next
}
/Host dplagueis/ {
    print $0
    print "    Hostname " ip
    getline
    next
}
{
    print
}
