#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'json'
require 'English'

$LOAD_PATH.unshift '/etc/puppet/tasks'
require 'deploy/utils'
require 'deploy/config'
require 'deploy/task'
require 'deploy/agent'
require 'deploy/action'
require 'deploy/action/puppet'
require 'deploy/action/exec'
require 'deploy/action/rspec'

set :port, 10000
set :bind, '0.0.0.0'

get '/' do
  return HTML if defined? HTML
  directory = File.dirname __FILE__
  file = File.join directory, 'rest.html'
  return 'No HTML file!' unless File.exists? file
  HTML = File.read file
end

get '/task' do
  tasks = Deploy::Utils.get_all_tasks
  tasks = tasks.map { |t| { 'task' => t.name, 'comment' => t.comment } }
  JSON.dump({ 'data' => tasks, 'success' => true})
end

post '/task/:name' do
  task = params[:name]
  directory = File.dirname __FILE__
  deploy = File.join directory, 'deploy.rb'
  system "#{deploy} daemon #{task}"
  exit_code = $CHILD_STATUS.exitstatus
  if exit_code == 0
    JSON.dump({ 'success' => true, 'report' => 'Task ' + task + ' run OK!' })
  else
    JSON.dump({ 'success' => false, 'report' => 'Task ' + task + ' run FAIL!' })
  end
end

put '/task/:name' do
  task = params[:name]
  agent = Deploy::Agent.new task.to_s
  report = agent.task_report_text
  if report
    return JSON.dump({ 'success' => true, 'report' => report });
  else
    return JSON.dump({ 'success' => false, 'report' => 'No report!' });
  end
end

delete '/task/:name' do
  task = params[:name]
  agent = Deploy::Agent.new task.to_s
  return JSON.dump({ 'success' => true, 'report' => 'Task ' + task + ' not running!' }) unless agent.is_running?
  result = agent.stop
  if result
    return JSON.dump({ 'success' => true, 'report' => 'Task ' + task + ' stop OK!' })
  else
    return JSON.dump({ 'success' => false, 'report' => 'Task ' + task + ' stop FAIL!' })
  end
end

get '/task/:name' do
  task = params[:name]
  agent = Deploy::Agent.new task.to_s
  status = agent.status
  pid = agent.pid
  JSON.dump({ 'pid' => pid, 'status' => status })
end