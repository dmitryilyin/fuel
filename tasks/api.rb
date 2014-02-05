#!/usr/bin/env ruby
$LOAD_PATH.unshift '/etc/puppet/tasks'
require 'tasks'

def run_action(action, directory, option)
  raise "Unknown action: #{action}" unless %w(pre run post deploy).include? action
  task = Tasks::Task.new directory

  case option
  when 'report'
    task.report_read action
  when 'raw'
    task.report_raw action
  when 'remove'
    task.report_remove action
  when 'check'
    exit task.success? action
  else
    task.send action
  end
  exit
end

def create_api_links(api = nil, task_dir = nil)
  api = File.join Tasks.config[:task_dir], 'api.rb' unless api
  task_dir = '.' unless task_dir
  actions = %w(pre run post deploy)
  actions.each do |a|
    symlink = File.join task_dir, a
    puts "#{api} => #{symlink}"
    File.unlink symlink if File.exists? symlink or File.symlink? symlink
    File.symlink api, symlink unless File.exists? symlink
    raise "#{symlink} is not a symlink!" unless File.symlink? symlink
  end
end

def create_links_for_puppet_tasks
  require 'find'
  raise 'No task dir!' unless Tasks.config[:task_dir] and File.directory? Tasks.config[:task_dir]
  Find.find(Tasks.config[:task_dir] + '/') do |path|
    next unless path.end_with? Tasks.config[:task_file]
    task_dir = File.dirname path
    manifest = File.join task_dir, Tasks.config[:puppet_manifest]
    next unless File.exists? manifest
    api = File.join Tasks.config[:task_dir], 'api.rb' unless api
    create_api_links api, task_dir
  end
end

###########################################################

option = $ARGV[0]

case option
  when 'links' then create_api_links
  when 'init' then create_api_links
  when 'autolinks' then create_links_for_puppet_tasks
  else begin
    action = File.basename $0
    directory = File.dirname $0
    run_action action, directory, option
  end
end
