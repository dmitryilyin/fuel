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
  when 'check_spec' then Tasks.check_if_spec_present
  else begin
    action = File.basename $0
    directory = File.dirname $0
    raise "Unknown action: #{action}" unless %w(pre run post deploy).include? action
    task = Tasks::Task.new directory

    case option
      when 'report'
        task.report_output action
      when 'raw'
        task.report_raw action
      when 'remove'
        task.report_remove action
      when 'check'
        exit task.success? action
      else
        task.send action
    end

  end
end
