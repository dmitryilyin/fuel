#!/usr/bin/env ruby
$LOAD_PATH.unshift '/etc/puppet/tasks'
require 'tasks'

action = File.basename $0
directory = File.dirname $0

def run_action(directory, action)
  raise "Unknown action: #{action}" unless %w(pre run post).include? action
  t = Tasks::Task.new directory
  option = $ARGV[0]

  case option
  when 'report'
    t.report_read action
  when 'raw'
    t.report_raw action
  when 'remove'
    t.report_remove action
  when 'check'
    exit t.success? action
  else
    t.send action
  end
end

run_action directory, action