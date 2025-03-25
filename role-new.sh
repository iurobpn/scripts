#!/usr/bin/bash

if [ -z $1 ]; then
  echo "Usage: $0 <role_name>"
  exit 1
fi
newrole=$1
mkdir -p roles/$newrole/{tasks,handlers,templates,files,vars,defaults,meta}
touch roles/$newrole/{tasks,handlers,templates,files,vars,defaults,meta}/main.yml
tree roles/$newrole
