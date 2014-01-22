#!/usr/bin/env ruby
require 'tasks'

action = File.basename $0
directory = File.dirname $0

def run_action(directory, action)
  raise "Unknown action: #{action}" unless %w(pre run post).include? action
  t = Tasks::Task.new directory
  if $ARGV[0] == 'report'
    t.report_read action
  elsif $ARGV[0] == 'raw'
    t.report_raw action
  elsif $ARGV[0] == 'remove'
    t.report_remove action
  else
    t.send action
  end
end

run_action directory, action