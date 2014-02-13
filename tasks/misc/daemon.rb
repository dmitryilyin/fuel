require 'rubygems'
require 'daemons'

# demo of daemonization

NAME = 'daemon_test'

def setproctitle(name)
  $0 = name.to_s
end

def daemon_code
  setproctitle "#{NAME}: daemon_code"
  loop do
    File.open '/tmp/daemon.txt', 'a+' do |file|
      time = Time.now
      file.puts "Time to log: #{time}"
      file.flush
      puts "Time to stdout: #{time}"
      sleep 1
    end
  end    
end

def stop_proc
  Proc.new do
    setproctitle "#{NAME}: stoping"
    sleep 5
    File.open '/tmp/daemon.txt', 'a' do |file|
      file.puts "Stop #{NAME} with pid: #{Process.pid} at #{Time.now}"
    end
  end
end

def main
  setproctitle "#{NAME}: starting"
  sleep 5
  File.open '/tmp/daemon.txt', 'w' do |file|
    file.puts "Start #{NAME} with pid: #{Process.pid} at #{Time.now}"
  end
  daemon_code
end

options = {
  :app_name   => NAME,
  :multiple   => false,
  :backtrace  => true,
  :monitor    => false,
  :ontop      => false,
  :dir_mode   => :normal,
  :dir        => "/var/run/#{NAME}",
  :log_dir    => "/var/log/#{NAME}",
  :log_output => true,
  :keep_pid_files => false,
  :hard_exit  => false,
  :stop_proc  => stop_proc, 
}

if File.exists? '/var/run/daemon_test/daemon_test.pid' # and pid is running and is ruby
  puts 'running!'
  exit 1
end

puts 'script before fork'

Daemons.call(options) do
  main
end

puts 'script after fork'
