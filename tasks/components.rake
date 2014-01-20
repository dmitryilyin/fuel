require 'find'

TESTS_DIR = File.dirname(File.expand_path(__FILE__))
SPEC_DIR = File.expand_path(TESTS_DIR + '/spec')

puppet_options = "--detailed-exitcodes"
puppet_options += " --verbose --debug --trace --evaltrace" if ENV['puppet_debug']
puppet_options += " --noop" if ENV['puppet_noop']

PUPPET_OPTIONS = puppet_options
RSPEC_OPTIONS = "--color -f doc"

def puppet(manifest_file)
  fail "No such manifest '#{Dir.pwd}/#{manifest_file}'!" unless File.exist?(manifest_file)
  sh "puppet apply #{PUPPET_OPTIONS} '#{manifest_file}'" do |ok, res|
    fail "Apply of manifest '#{manifest_file}' failed with exit code #{res.exitstatus}!" unless [0,2].include?(res.exitstatus)
  end
end

def rspec(test_name)
  rspec_file = "#{SPEC_DIR}/#{test_name}_spec.rb"
  if File.exists?(rspec_file)
    sh "rspec #{RSPEC_OPTIONS} '#{rspec_file}'" do |ok, res|
      fail("Test #{test_name} failed with exit code #{res.exitstatus}!") unless ok
    end
  else
    puts "Spec file for test '#{test_name}' doesn't exist! Skipping test phase."
  end
end

Dir.chdir(TESTS_DIR) || exit(1)

Find.find('.') do |path|
  next unless File.file?(path)
  next unless path.end_with?('.pp')
  path.sub!('./','')
  test_name = path.chomp('.pp')
  namespace test_name do
    task :run => [ :apply, :test ] do
      puts "#{test_name} run ends"
    end
    task :apply do
      puppet(path)
      puts "#{test_name} have been applied!"
    end
    task :test do
      rspec(test_name)
      puts "#{test_name} have been tested!"
    end
    desc "#{test_name} deployment task"
  end
  task test_name do
    Rake::Task["#{test_name}:apply"].invoke
    Rake::Task["#{test_name}:test"].invoke
  end
end
