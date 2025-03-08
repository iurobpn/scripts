#!/bin/bash

while true;
do
    import -window $(wmctrl -l -i | sed -n '/Zellij (blender)/p' | awk '{print $1}') blender_screenshot_$(date +%Y%m%d_%H%M%S).png
    sleep 5m
done
