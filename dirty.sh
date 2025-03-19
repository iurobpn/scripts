#!/usr/bin/fish
# get dirty repos from gita output
function drs
   gita ll | awk '!/\[\]/ && !/traffic/ && !/\[\$/'
end

