#!/bin/bash

qemu-system-x86_64 \                                                                                                                                                               13s 16:33:13
                            -enable-kvm \
                            -m 2048 \
                            -drive file=alpine.qcow2,if=virtio,cache=writeback \
                            -netdev user,id=net0,hostfwd=tcp::2222-:22 \
                            -device virtio-net-pci,netdev=net0 \
                            -display sdl
