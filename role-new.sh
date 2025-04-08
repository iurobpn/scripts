#!/usr/bin/bash

# roles/
#     common/               # this hierarchy represents a "role"
#         tasks/            #
#             main.yml      #  <-- tasks file can include smaller files if warranted
#         handlers/         #
#             main.yml      #  <-- handlers file
#         templates/        #  <-- files for use with the template resource
#             ntp.conf.j2   #  <------- templates end in .j2
#         files/            #
#             bar.txt       #  <-- files for use with the copy resource
#             foo.sh        #  <-- script files for use with the script resource
#         vars/             #
#             main.yml      #  <-- variables associated with this role
#         defaults/         #
#             main.yml      #  <-- default lower priority variables for this role
#         meta/             #
#             main.yml      #  <-- role dependencies
#         library/          # roles can also include custom modules
#         module_utils/     # roles can also include custom module_utils
#         lookup_plugins/   # or other types of plugins, like lookup in this case
#
#     webtier/              # same kind of structure as "common" was above, done for the webtier role
#     monitoring/           # ""
#     fooapp/               # ""

if [ -z $1 ]; then
    echo "Usage: $0 <role_name>"
    exit 1
fi
newrole=$1
mkdir -p roles/$newrole/{tasks,handlers,templates,files,vars,defaults,meta,library,module_utils,lookup_plugins}
touch roles/$newrole/{tasks,meta}/main.yml
# create templates dor meta and takss/main.yml
touch roles/$newrole/README.md
cat > roles/$newrole/README.md <<-END
---
# {{role_name}} Role

This Ansible role installs {{ role_name }}.

## Role Variables

*None defined by default.*

## Example Playbook

- hosts: all
roles:
- rust
END
#
tree roles/$newrole
