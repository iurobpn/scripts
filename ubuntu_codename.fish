#!/usr/bin/fish

function ubuntu_codename
    cat /etc/os-release | sed -n "/UBUNTU_CODENAME/p" | sed -e "s/[^=]\+=\(.*\)/\1/"
end
