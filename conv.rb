#!/usr/bin/env ruby -n

$_ =~ /^\$(\S+).*/
puts "#{$1}: <%= @#{$1} %>"
