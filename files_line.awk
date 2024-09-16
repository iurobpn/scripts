#!/bin/awk -f

BEGIN {
    OFS=":";
    FS=":";
    k = 0;
}

# /^.*:[0-9]+:.*$/
{
    line_nr=$2;
    file=$1;
    counter=0;
    cmd = "ls " file " >  /dev/null 2>&1 ";
    if (system(cmd) != 0) {
        next;
    }
    if (length(file) == 0) {
        next;
    }
    while (getline < file) {
            counter++;
    }
    r = (rand()*(counter - 1) + 1)*2;
    r = r/2;
    r = r - r%1;

    k++;
    print file, r,  " ";
}

