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
  agent.run
end

def daemon(task)
  raise 'No task given!' unless task
  agent = Deploy::Agent.new task.to_s
  agent.daemonize = true
  agent.run
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
    agent.stop
  else
    puts "Task #{task} is not running!"
  end
end

def listen
  require 'sinatra'
  require 'JSON'
  set :port, 10000
  set :bind, '0.0.0.0'

  get "/" do
    directory = File.dirname __FILE__
    file = File.join directory, 'rest.html'
    return 'No HTML file!' unless File.exists? file
    File.read file
  end

  get '/task' do
    tasks = Deploy::Utils.get_all_tasks
    tasks = tasks.map { |t| { 'task' => t.name } }
    JSON.dump({ 'data' => tasks, 'success' => true})
  end

  post '/task/:name' do
    task = params[:name]
    agent = Deploy::Agent.new task.to_s
    agent.daemonize = true
    code = agent.run_foreground
    report = agent.task_report_text
    if code == 0
      return JSON.dump({ 'success' => true, 'report' => report })
    else
      return JSON.dump({ 'success' => false, 'report' => report })
    end
  end


end

#####################

case action
  when 'list' then list
  when 'run'  then run task
  when 'runrep' then begin
    run task
    report task
  end
  when 'daemon' then daemon task
  when 'report' then report task
  when 'status' then status task
  when 'stop'   then stop task
  when 'config' then Deploy::Utils.show_config
  when 'listen' then listen
  else raise "Unknown action: #{action}!"
end
