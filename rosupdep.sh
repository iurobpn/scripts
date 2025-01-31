#!/bin/bash
cd ~/ros2_ws
rosdep install -i --from-path src --rosdistro jazzy -y
cd -
