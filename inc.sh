#!/usr/bin/fish

if test -z $argv[1]
    set fsize 2
else
    set fsize $argv[1]
end

set fsize 2
set -gx WEZ_FONT_SIZE math ($WEZ_FONT_SIZE + $fsize)

cat ~/.config/wezterm/wezterm.lua | sed -e 's/^-- \(config.font_size\)/\1' -e 's/^\(config.font_size = \).*$/\1 $WEZ_FONT_SIZE/' #> ~/.config/wezterm/wezterm.lua
