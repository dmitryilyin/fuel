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

action = $ARGV[0]
task = $ARGV[1]

unless action or task
  action = 'list'
end

def list
  tasks = Deploy::Utils.get_all_tasks
  Deploy::Utils.print_tasks_list tasks
end

def run(task)
  raise 'No task given!' unless task
  agent = Deploy::Agent.new task.to_s
  agent.daemonize = false
  exit agent.run
end

def daemon(task)
  raise 'No task given!' unless task
  agent = Deploy::Agent.new task.to_s
  agent.daemonize = true
  exit agent.run
end

def runrep(task)
  raise 'No task given!' unless task
  agent = Deploy::Agent.new task.to_s
  agent.daemonize = false
  code = agent.run
  puts agent.task_report_text  
  exit code
end

def report(task)
  raise 'No task given!' unless task
  agent = Deploy::Agent.new task.to_s
  puts agent.task_report_text
end

def status(task)
  raise 'No task given!' unless task
  agent = Deploy::Agent.new task.to_s
  status = agent.status
  pid = agent.pid
  running = agent.is_running?
  puts "Running at pid: #{pid}" if running
  puts "Status: #{status}"
  exit running
end

def stop(task)
  raise 'No task given!' unless task
  agent = Deploy::Agent.new task.to_s
  if agent.is_running?
    exit 0 if agent.stop
  else
    puts "Task #{task} is not running!"
  end
  exit 1
end

#####################

case action
  when 'list' then list
  when 'run'  then run task
  when 'runrep' then runrep task
  when 'daemon' then daemon task
  when 'report' then report task
  when 'status' then status task
  when 'stop'   then stop task
  when 'config' then Deploy::Utils.show_config
  else raise "Unknown action: #{action}!"
end
