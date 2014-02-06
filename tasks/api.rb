#!/usr/bin/env ruby
$LOAD_PATH.unshift '/etc/puppet/tasks'
require 'tasks'

option = $ARGV[0]

case option
  when 'init' then Tasks.create_api_links
  when 'links' then Tasks.create_all_task_links
  when 'puppet_links' then Tasks.create_all_task_links false, true
  when 'file_links' then Tasks.create_all_task_links true, false
  when 'remove' then Tasks.remove_all_task_links
  else begin
    action = File.basename $0
    directory = File.dirname $0
    Tasks.run_action action, directory, option
  end
end
