#!/bin/awk -f
BEGIN {
    FS = "'"
}

FNR==NR {
    # Store lines from wp-config.php
    lines[NR] = $0
    keys[NR] = $2
    total_lines = NR
    next
}
{
    for (i=1; i<=total_lines; i++) {
        if ($2 == keys[i]) {
            print lines[i]
            next
        }
    }
    print $0
}

