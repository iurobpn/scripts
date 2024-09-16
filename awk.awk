#!/bin/awk -f
BEGIN {
    N=10
    for (i = 1; i < N; i++) {
        printf "i: %s\n", i
    }
}
END {
    print $1"done"
    exit;
}
