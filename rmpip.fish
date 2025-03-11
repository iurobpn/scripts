#!/usr/bin/fish

set pkgs (cat $argv)

for app in $pkgs
    pip uninstall $app || echo "$app not installed"
end
