#!/usr/bin/env ruby
$LOAD_PATH.unshift '/etc/puppet/tasks'
require 'rubygems'
require 'deploy'
require 'pry'

agent = Deploy::Agent.new 'test::long'
binding.pry

