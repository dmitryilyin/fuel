#!/usr/bin/env ruby
$LOAD_PATH.unshift '/etc/puppet/tasks'
require 'tasks'

def run_action(action, directory, option)
  raise "Unknown action: #{action}" unless %w(pre run post deploy).include? action
  directory = File.dirname directory if directory.end_with? 'install.d'
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

def create_api_links
  api_path = File.dirname $0
  api_file = File.basename $0
  directory = '.'
  actions = %w(pre run post deploy)
  actions.each do |a|
    symlink = File.join directory, a
    File.unlink symlink if File.exists? symlink
    api = File.join api_path, api_file
    File.symlink api, symlink unless File.exists? symlink
    raise "#{a} is not a symlink!" unless File.symlink? symlink
  end
#  install_d = File.join directory, 'install.d'
#  File.unlink install_d if File.exists? install_d and not File.directory? install_d
#  Dir.mkdir install_d unless File.exists? install_d
#  raise 'No install.d dir!' unless File.directory? install_d
#  deploy_file = File.join directory, 'install.d', 'deploy'
#  File.unlink deploy_file if File.exists? deploy_file
#  deploy_content = <<END
##!/bin/sh
#file=$0
#dir=`dirname ${file}`
#cd "${dir}" || exit 1
#cd ..
#./deploy
#END
#  File.open(deploy_file, 'w') { |file| file.write deploy_content } unless File.exists? deploy_file
#  File.chmod 0755, deploy_file
#  raise "#{deploy_file} was not created!" unless File.exists? deploy_file
  exit
end

###########################################################

option = $ARGV[0]
create_api_links if option == 'links'

action = File.basename $0
directory = File.dirname $0
run_action action, directory, option
