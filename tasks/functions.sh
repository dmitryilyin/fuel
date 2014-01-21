#!/bin/sh
reports="/var/log/tasks"
pre_spec="spec/pre_spec.rb"
post_spec="spec/post_spec.rb"
manifest="site.pp"
pre_xml="pre.xml"
post_xml="post.xml"
run_xml="run.xml"

check_pwd() {
  current_dir="`pwd`"
  current_dir=`basename "${current_dir}"`
  if [ "${current_dir}" != 'tasks' ]; then
    echo "You should ran tasks from the root of your 'tasks' folder!"
    exit 1
  fi
}

prepare() {
  check_pwd
  task_file="${0}"
  task_dir=`dirname ${0}`
  #cd "${task_dir}"
  #task_dir=`pwd`
  #task_name=`basename ${task_dir}`
  task_name="`echo ${task_dir} | sed -e 's/^\.*\/*//g' -e 's/\//::/g'`"
  task_type=`basename ${task_file}`
  mkdir -p "${reports}/${task_name}"
}

no_test_xml() {
date=`date --iso-8601='seconds'`
cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuite tests="0" failures="0" errors="0" timestamp="${date}" time="0.0">
  <testcase classname="no_test" time="0.0" name="No test" />
</testsuite>
EOF
}

puppet_fail_xml() {
date=`date --iso-8601='seconds'`
cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuite tests="0" failures="1" errors="0" timestamp="${date}" time="0.0">
  <testcase classname="puppet_run" time="0.0" name="Puppet run">
    <failure type="Puppet::Error" message="Puppet run had errors!">
      <![CDATA[There was an error in this task!]]>
    </failure>
  </testcase>
</testsuite>
EOF
}

puppet_ok_xml() {
date=`date --iso-8601='seconds'`
cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuite tests="0" failures="0" errors="0" timestamp="${date}" time="0.0">
  <testcase classname="puppet_run" time="0.0" name="Puppet run" />
</testsuite>
EOF
}

no_task_xml() {
date=`date --iso-8601='seconds'`
cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuite tests="0" failures="1" errors="0" timestamp="${date}" time="0.0">
  <testcase classname="no_task" time="0.0" name="No task">
    <failure type="Task::Error" message="There is no task!">
      <![CDATA[This task has nothing to do!]]>
    </failure>
  </testcase>
</testsuite>
EOF
}

prepare

if [ "${task_type}" = "run" ]; then
  if [ -f "${task_dir}/${manifest}" ]; then
    puppet apply --detailed-exitcodes -vd "${task_dir}/${manifest}"
    ec="${?}"
    if [ "${ec}" = "0" -o "${ec}" = "2" ]; then
      puppet_ok_xml > "${reports}/${task_name}/${run_xml}"
      exit "${ec}"
    else
      puppet_fail_xml > "${reports}/${task_name}/${run_xml}"
      exit "${ec}"
    fi
  else
    echo "No puppet manifest!"
    puppet_fail_xml > "${reports}/${task_name}/${run_xml}"
    exit 1
  fi
elif [ "${task_type}" = "pre" ]; then
  if [ -f "${task_dir}/${pre_spec}" ]; then
    cd "${task_dir}"
    rspec -f RspecJunitFormatter --out "${reports}/${task_name}/${pre_xml}" "${pre_spec}"
    ec="${?}"
    return "${ec}"
  else
    no_test_xml > "${reports}/${task_name}/${pre_xml}"
    return 0
  fi
elif [ "${task_type}" = "post" ]; then
  if [ -f "${task_dir}/${post_spec}" ]; then
    cd "${task_dir}"
    rspec -f RspecJunitFormatter --out "${reports}/${task_name}/${post_xml}" "${post_spec}"
    ec="${?}"
    return "${ec}"
  else
    no_test_xml > "${reports}/${task_name}/${post_xml}"
    return 0
  fi
else
  echo "Unknown action!"
  exit 1
fi
