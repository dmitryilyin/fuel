module Deploy

  # Controlls the process of tasks execution, tests, daemonization, pids and logs #
  class Agent
    def initialize(task_name)
      set_title "agent: #{task_name} - init"
      library_dir = Deploy::Config[:library_dir]
      raise "Library directory #{library_dir} does not exist!" unless library_dir and File.directory? library_dir
      task_dir = Deploy::Config[:task_dir]
      raise "Base task directory #{task_dir} does not exist!" unless task_dir and File.directory? task_dir
      report_dir = Deploy::Config[:report_dir]
      raise "Report directory #{report_dir} is not set!" unless report_dir
      pid_dir = Deploy::Config[:pid_dir]
      raise "Report directory #{pid_dir} is not set!" unless pid_dir
      task_directory = task_name.gsub '::', '/'
      task_directory = File.expand_path File.join library_dir, task_directory
      raise "Task directory #{task_directory} does not exist!" unless File.directory? task_directory
      @task = Deploy::Task.new task_directory
      @task_name = task.name
      @daemonize = true
      task.set_plugins
      Deploy::Utils.debug "Created #{self.class} for task #{task.name}"
      set_title "agent: #{task_name} - idle"
    end

    attr_reader :task
    attr_reader :task_name
    attr_accessor :daemonize

    def call
      set_status 'pre'
      task.pre
      if task.fail? :pre
        set_status 'pre failed'
        return 1
      end
      set_status 'run'
      task.run
      if task.fail? :run
        set_status 'run failed'
        return 2
      end
      set_status 'post'
      task.post
      if task.fail? :post
        set_status 'post failed'
        return 3
      end
      set_status 'end'
      0
    end

    def set_status(status)
      Deploy::Utils.debug "Agent task: #{task_name} status: #{status}"
      set_title "agent: #{task_name} - #{status}"
      @status = status
      File.open status_file_path, 'w' do |f|
        f.write status
      end
    end

    def set_title(title)
      $0 = title.to_s
    end

    def status
      set_title "agent: #{task_name} - status"
      return 'idle' unless has_status_file?
      status = File.read(status_file_path).chomp
      set_title "agent: #{task_name} - idle"
      status
    end

    def daemon_app_name
      'agent'
    end

    def status_file_name
      'status'
    end

    def process_title_string(status)
      "agent: #{task_name} - #{status.to_s}"
    end

    def daemon_option
      {
          :app_name => daemon_app_name,
          :multiple => false,
          :backtrace => true,
          :monitor => false,
          :ontop => !daemonize,
          :dir_mode => :normal,
          :dir => task_pid_dir,
          :log_dir => task_report_dir,
          :log_output => true,
          :keep_pid_files => false,
          :hard_exit => false,
      }
    end

    def has_pid_file?
      File.exists? pid_file_path
    end

    def read_pid_file
      return nil unless has_pid_file?
      File.read pid_file_path.chomp.to_i
    end

    def is_running?
      # TODO check if process with this pid exists and is ruby
      has_pid_file?
    end

    def run_daemon
      require 'daemons'
      if is_running?
        return 1
      end

      Daemons.call(daemon_option) do
        call
      end

      0
    end

    def status_file_path
      return @status_file_path if @status_file_path
      @status_file_path = File.join task_report_dir, status_file_name
    end

    def pid_file_path
      return @pid_file_path if @pid_file_path
      @pid_file_path =  File.join task_pid_dir, daemon_app_name
    end

    def task_report_dir
      return @task_report_dir if @task_report_dir
      @task_report_dir = File.join Deploy::Config[:report_dir], task_name
      unless File.exists? @task_report_dir
        require 'fileutils'
        FileUtils.mkdir_p @task_report_dir
      end
      raise "No report directory '#{@task_report_dir}'!" unless File.directory? @task_report_dir
      @task_report_dir
    end

    def task_pid_dir
      return @task_pid_dir if @task_pid_dir
      @task_pid_dir = File.join Deploy::Config[:pid_dir], task_name
      unless File.exists? @task_pid_dir
        require 'fileutils'
        FileUtils.mkdir_p @task_pid_dir
      end
      raise "No report directory '#{@task_pid_dir}'!" unless File.directory? @task_pid_dir
      @task_pid_dir
    end

    def has_status_file?
      File.file? status_file_path
    end

    def remove_status_file
      File.unlink status_file_path if File.file? status_file_path
    end

    def report
      set_title "agent: #{task_name} - report"
      pre_report = task.report_read :pre
      run_report = task.report_read :run
      post_report = task.report_read :post
      report = {
          :pre => pre_report,
          :run => run_report,
          :post => post_report,
      }
      set_title "agent: #{task_name} - idle"
      report
    end

    def stop
      set_title "agent: #{task_name} - stop"
      # TODO implement
      set_title "agent: #{task_name} - idle"
    end

  end # class

end # module
