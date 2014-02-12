require 'rubygems'
require 'daemons'

# demo of daemonization

Name = 'daemon_test'

def setproctitle(name)
  $0 = name.to_s
end

def daemon_code
  setproctitle "#{Name}: daemon_code"
  loop do
    File.open '/tmp/daemon.txt', 'a+' do |file|
      time = Time.now
      file.puts "Time to log: #{time}"
      puts "Time to stdout: #{time}"
      sleep 1
    end
  end    
end

def stop_proc
  Proc.new do
    setproctitle "#{Name}: stoping"
    sleep 5
    File.open '/tmp/daemon.txt', 'a' do |file|
      file.puts "Stop #{Name} with pid: #{Process.pid} at #{Time.now}"
    end
  end
end

def main
  setproctitle "#{Name}: starting"
  sleep 5
  File.open '/tmp/daemon.txt', 'w' do |file|
    file.puts "Start #{Name} with pid: #{Process.pid} at #{Time.now}"
  end
  daemon_code
end

options = {
  :app_name   => Name,
  :multiple   => false,
  :backtrace  => true,
  :monitor    => false,
  :ontop      => false,
  :dir_mode   => :normal,
  :dir        => "/var/run/#{Name}",
  :log_dir    => "/var/log/#{Name}",
  :log_output => true,
  :keep_pid_files => false,
  :hard_exit  => false,
  :stop_proc  => stop_proc, 
}

if File.exists? '/var/run/daemon_test/daemon_test.pid'
  puts 'running!'
  exit 1
end

Daemons.call(options) do
  main
end
