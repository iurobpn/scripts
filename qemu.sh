#!/bin/bash
# This script sets up a QEMU virtual machine with specified parameters.
# It uses KVM for hardware acceleration and configures networking and display options.
# It also forwards port 22 from the host to the guest for SSH access.

echo args: $#

if [ "$1" == "-w" ]; then
    # If the first argument is -w, set the VIRTIO_WIN_ISO variable
    # run `qemuwin_inst 16G win.img win.iso`
    WIN_INST=1
    DRIVE=ide
    shift 1
else
    # Otherwise, set the VIRTIO_WIN_ISO variable to an empty string
    WIN_INST=0
    VIRTIO_WIN_ISO=""
fi
# if [ "$1" == "-ide" ]; then
#     # If the first argument is -ide, set the if=ide option for the drive
#     DRIVE=ide
#     shift 1
# else
#     DRIVE=virtio
# fi

if [ $# -lt 2 ]; then
    echo "Usage: $0 [-w|-ide] <RAM> <DRIVE_FILE> [<ISO_FILE>]"
    exit 1
fi
# Set the RAM size and drive file from command line arguments
RAM=$1
IMAGE=$2
EXT="${IMAGE##*.}"
if [ "$EXT" != "qcow2" ]; then
    FORMAT=raw
else
    FORMAT=qcow2
fi
# Set the ISO file if provided, otherwise use a default

# Check if the ISO_FILE has been provided
if [ $# -ge 3 ]; then
    ISO_FILE=$3
    OPTS="-cdrom $ISO_FILE"
else
    OPTS=""
fi
[ -z $RAM ] && echo "RAM is empty" && exit 1
[ -z $IMAGE ] && echo "DRIVE_FILE is empty" && exit 1
[ -z $ISO_FILE ] && echo "ISO_FILE is empty"
echo "Starting QEMU with RAM: $RAM, Drive: $IMAGE, ISO: $ISO_FILE"
qemurun() {
    qemu-system-amd64 \
        -enable-kvm \
        -m $RAM \
	-cpu max \
	-smp 8 \
        -drive file=$IMAGE,if=$DRIVE,format=$FORMAT \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net-pci,netdev=net0 \
        $OPTS \
        -display sdl
}

qemuwin () {
    qemu-system-x86_64 \
        -enable-kvm \
        -m $RAM \
        -drive file=$IMAGE,if=ide,format=raw \
        $OPTS \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net-pci,netdev=net0 \
        -display sdl
}

# if [ $WIN_INST -eq 1 ]; then
#     echo "Starting QEMU with Windows setup"
#     qemuwin
# else
    # Otherwise, use the default Linux setup
    # echo "Starting QEMU with Linux setup"
    qemurun
# fi

# windows installation process
# first run
# `qemuwin 16G win.img win.iso`
# `qemuwin 16G win.img virtio.iso`
# install virtio driverswin
# run `qemurun 16G win.img`
# qemuwin_inst
