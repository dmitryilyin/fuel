require 'rubygems'
require "rexml/document"
include REXML

def parse_xunit(file_name)
  raise "No file given!" unless file_name
  xml = REXML::Document.new(File.open(file_name, "r"))
  raise "Could not parse file!" unless xml

  testsuite = xml.root.elements['/testsuite']
  errors = testsuite.attributes["failures"].to_i

  testcases = xml.root.elements.to_a('testcase')

  testcases.each do |tc|
    success = true
    message = ''
    failures = tc.elements.to_a('failure')
    if failures.any?
      success = false
      message = failures.first.texts.join.gsub(/\s+/,' ')
    end
    puts "#{tc.attributes['name']} | #{success ? 'OK' : 'FAIL'} | #{message}"
  end

  puts
  puts "Errors: #{errors}"
  exit errors
end

if __FILE__ == $0
  file_name = ARGV[0]
  parse_xunit file_name
end
