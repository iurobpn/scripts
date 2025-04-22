#!/bin/bash
# set -e
osrel2ubuntu () {
    export LSB_OS_RELEASE=/tmp/lsb-os-release-ubuntu
    ! [ -f "/tmp/lsb-os-release-ubuntu" ] && cat <<LSBEND > /tmp/lsb-os-release-ubuntu
export PRETTY_NAME="Ubuntu 24.04.2 LTS"
export NAME="Ubuntu"
export VERSION_ID="24.04"
export VERSION="24.04.2 LTS (Noble Numbat)"
export VERSION_CODENAME=noble
export ID=ubuntu
export ID_LIKE=debian
export HOME_URL="https://www.ubuntu.com/"
export SUPPORT_URL="https://help.ubuntu.com/"
export BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
export PRIVACY_POLICY_URL="https://www.ubuntu.com/"
export UBUNTU_CODENAME=noble
LSBEND
}
# sudo cp /tmp/lsb-release-ubuntu /etc/lsb-release-ubuntu
release_mint2ubuntu () {
    sudo cp -v /etc/lsb-release-ubuntu /tmp/lsb-release-ubuntu # temporary backup
    sudo cp -v /etc/lsb-release /tmp/lsb-release-mint_1 # temporary backup
    if ! [ -f "/etc/lsb-release-mint" ]; then
        sudo cp -v /etc/lsb-release /tmp/lsb-release-mint # temporary backup
        sudo cp -v /etc/lsb-release /etc/lsb-release-mint
    else
        sudo cp -v /etc/lsb-release-mint /tmp/lsb-release-mint # temporary backup
    fi
    sudo cp -v /etc/lsb-release-ubuntu /etc/lsb-release
    source /etc/lsb-release-ubuntu
}

release_ubuntu2mint () {
    sudo cp -v /etc/lsb-release /tmp/lsb-release-ubuntu2mint_in
    [ -f "/etc/lsb-release-mint" ] && sudo cp -v /etc/lsb-release-mint /etc/lsb-release
    sudo cp -v /etc/lsb-release-mint /etc/lsb-release
    source /etc/lsb-release-mint
}

rosdep_mint () {
    echo $@
    osrel2ubuntu
    rosdep $@
    export LS_OS_RELEASE=
}
