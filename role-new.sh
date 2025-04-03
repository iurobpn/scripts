#!/usr/bin/bash


myfunc() {
    echo "hello $1"
}

# Same as above (alternate syntax)
function myfunc2 {
    echo "hello $1"
}

function mkrole {
    echo "i"
}

    # if [ -z $1 ]; then
    #     echo "Usage: $0 <role_name>"
    #     exit 1
    # fi
    # newrole=$1
    # mkdir -p roles/$newrole/{tasks,handlers,templates,files,vars,defaults,meta}
    # touch roles/$newrole/{tasks,meta}/main.yml
    # create tempaltes dor meta and takss/main.yml
    # touch roles/$newrole/README.md
#     echo <<-EOF > roles/$newrole/README.md
#         ---
#         # {{role_name}} Role
#
#         This Ansible role installs {{ role_name }}.
#
#         ## Role Variables
#
#         *None defined by default.*
#
#         ## Example Playbook
#
#         - hosts: all
#         roles:
#         - rust
# EOF
#
# tree roles/$newrole
