#!/usr/bin/fish

if [ $# -eq 0 ]; then
    set fsize 2
else
    set fsize $argv[1]
fi

set -gx WEZ_FONT_SIZE math ($WEZ_FONT_SIZE - $fsize)

cat ~/.config/wezterm/wezterm.lua | sed -e 's/^-- \(config.font_size\)/\1' -e 's/^\(config.font_size = \).*$/\1 $WEZ_FONT_SIZE/' > ~/.config/wezterm/wezterm.lua
