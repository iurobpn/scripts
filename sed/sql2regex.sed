#!/bin/bash

s/(/\\(/g
s/)/\\)/g
s/(|)/\\&/g
s/#[a-z]\+/\\(&\\)/g
s/ \? or \?/|/g
s/ \? and \?/ /g
s=\(.*\) \(.*\)=#!/bin/bash\nsed -n '/\1/p' -n '/\2/p'=g
