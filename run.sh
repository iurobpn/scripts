#!/usr/bin/bash
xrun () {
    xhost +
    docker run \
        --env="DISPLAY" \
        --env="QT_X11_NO_MITSHM=1" \
        --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
        --device /dev/kfd \
        --device /dev/dri \
        --security-opt seccomp=unconfined \
        --group-add video \
        "$@"
    }
