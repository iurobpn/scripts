#!/bin/awk -f
#fd . -tf -d 1 -I

# /^[a-zA-Z]+\.[a-zA-Z.]+/ {
/\./ {
    # if (match("^.*\\..*",$0)) {
    # if ( $0 ~ /^.*\..+$/ ) {
        # while ($0 ~/\.+/) {
            sub(/.*\./, "", $0);
        # }
        # print substr($0, RSTART+1);
        print $0;
#     } else {
#         print "No extension found";
#     }
}
