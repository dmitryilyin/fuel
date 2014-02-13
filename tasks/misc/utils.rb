#!/usr/bin/env ruby
$LOAD_PATH.unshift '/etc/puppet/tasks'
require 'deploy/config'
require 'deploy/task'
require 'deploy/utils'

option = $ARGV[0]

case option

  when 'init' then Deploy::Utils.create_api_links
  when 'links' then Deploy::Utils.create_all_task_links
  when 'remove' then Deploy::Utils.remove_all_task_links
  when 'check_spec' then Deploy::Utils.check_if_spec_present

  else begin
    puts "There is no options #{option}"
    puts 'options: init, links, remove, check_spec'
    exit 1
  end

end
