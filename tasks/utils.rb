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
actions = %w(pre run post)

default_task_file = <<EOF
:comment: New task title string
:description: New task long description
#:pre_plugin:
#:pre_params:
#:pre_timeout:
#:pre_autoreport:
#:run_plugin:
#:run_params:
#:run_timeout:
#:run_autoreport:
#:post_plugin:
#:post_params:
#:post_timeout:
#:post_autoreport:
EOF

case option
  when 'taskapi' then
    begin
      api = File.join Deploy::Config[:task_dir], Deploy::Config[:api_file]
      task_directory = '.'
      actions.each do |a|
        symlink = File.join task_directory, a
        File.unlink symlink if File.symlink? symlink
        File.symlink api, symlink unless File.exists? symlink
      end
    end
  when 'mktask'
    task_directory = $ARGV[1] ? $ARGV[1] : '.'
    unless task_directory == '.'
      require 'fileutils'
      FileUtils.mkdir_p task_directory
    end
    task_file = File.join task_directory, Deploy::Config[:task_file]
    unless File.exists? task_file
      f = File.open task_file, 'w'
      f.write default_task_file
      f.close
    end
  else
    raise "Option #{option} is not supported!"
end
