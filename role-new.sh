#!/usr/bin/bash

if [ -z $1 ]; then
  echo "Usage: $0 <role_name>"
  exit 1
fi
newrole=$1
mkdir -p roles/$newrole/{tasks,handlers,templates,files,vars,defaults,meta}
touch roles/$newrole/{tasks,meta}/main.yml
# create tempaltes dor meta and takss/main.yml
touch roles/$newrole/README.md
echo '---\
# {{role_name}} Role

This Ansible role installs {{ role_name }}.

## Role Variables

*None defined by default.*

## Example Playbook

```yaml
- hosts: all
  roles:
    - rust
```
' > roles/$newrole/README.md
# New role
tree roles/$newrole
