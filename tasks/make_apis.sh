#!/bin/sh
API='/etc/puppet/tasks/api.rb'
ROOT_DIR="`pwd`"

find . -name 'site.pp' | while read site_pp; do
  task_dir="`dirname ${site_pp}`"
  cd "${ROOT_DIR}/${task_dir}" || {
    echo "Cannot cd to ${task_dir}"
    continue
  } 
  "${API}" init
  cd "${ROOT_DIR}"
done
