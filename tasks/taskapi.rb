#!/usr/bin/env ruby
$LOAD_PATH.unshift '/etc/puppet/tasks'
require 'deploy/utils'
require 'deploy/config'
require 'deploy/task'
require 'deploy/agent'
require 'deploy/action'
require 'deploy/action/puppet'
require 'deploy/action/exec'
require 'deploy/action/rspec'

option = $ARGV[0]
action = File.basename $0
directory = File.dirname $0
actions = %w(pre run post)

raise "Unknown action: #{action}" unless actions.include? action
action = action.to_sym
task = Deploy::Task.new directory
task.set_plugins

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
