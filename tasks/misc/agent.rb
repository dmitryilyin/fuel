#!/usr/bin/env ruby
$LOAD_PATH.unshift '/etc/puppet/tasks'
require 'rubygems'
require 'pry'

agent = Tasks::Agent.new 'checks::support'
binding.pry

