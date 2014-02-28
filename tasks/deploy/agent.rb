require 'rubygems'

module Deploy

  # Controlls the process of tasks execution, tests, daemonization, pids and logs #
  class Agent
    # @param task_name [String] A name of task this agent should run
    def initialize(task_name)
      set_process_title "agent: #{task_name} - init"
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
      set_process_title "agent: #{task_name} - idle"
    end

    # @return [Deploy::Task]
    attr_reader :task
    # @return [String]
    attr_reader :task_name
    # @return [TrueClass,FalseClass]
    attr_accessor :daemonize

    # Execute the task of this agent
    # @return [Numeric]
    def call
      set_agent_status 'pre'
      task.pre
      if task.fail? :pre
        set_agent_status 'pre failed'
        return 1
      end
      set_agent_status 'run'
      task.run
      if task.fail? :run
        set_agent_status 'run failed'
        return 2
      end
      set_agent_status 'post'
      task.post
      if task.fail? :post
        set_agent_status 'post failed'
        return 3
      end
      set_agent_status 'end'
      0
    end

    # Set this agent's status file and title
    # @param status [String]
    def set_agent_status(status)
      Deploy::Utils.debug "Agent task: #{task_name} status: #{status}"
      set_process_title "agent: #{task_name} - #{status}"
      @status = status
      File.open status_file_path, 'w' do |f|
        f.write status
      end
    end

    # set process name visible in ps and top
    # @param title [String]
    def set_process_title(title)
      $0 = title.to_s
    end

    # get this agent's status from status file
    # @return [String]
    def status
      set_process_title "agent: #{task_name} - status"
      return 'idle' unless has_status_file?
      status = File.read(status_file_path).chomp
      set_process_title "agent: #{task_name} - idle"
      status
    end

    def daemon_app_name
      'agent'
    end

    def status_file_name
      'status'
    end

    # @return [String] Construct the title string for this process
    def process_title_string(status)
      "agent: #{task_name} - #{status.to_s}"
    end

    # @return [Hash] A set of daemon options
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

    # @return [TrueClass,FalseClass] Does the pid file exist?
    def has_pid_file?
      File.exists? pid_file_path
    end

    # @return [Numeric,NilClass] Pid of the running agent from pid file if any
    def pid
      return nil unless File.exists? pid_file_path
      File.read(pid_file_path).chomp.to_i
    end

    # @return [TrueClass,FalseClass] Is the agent for this task running?
    def is_running?
      # TODO check if process with this pid exists and is ruby
      has_pid_file?
    end

    # Run the task in background as a separate daemon process
    def run_background
      require 'daemons'
      if is_running?
        Deploy::Utils.debug "Already running task #{task_name} at pid #{pid} status #{status}!"
        return 1
      end

      Daemons.call(daemon_option) do
        call
      end

      0
    end

    # Run the task in foreground inside the current process
    def run_foreground
      if is_running?
        Deploy::Utils.debug "Already running task #{task_name} at pid #{pid} status #{status}!"
        return 1
      end
      call
    end

    # run this agent's task either in background or in foreground
    # depending on agent's settings
    def run
      if daemonize
        run_background
      else
        run_foreground
      end
    end

    # @return [String] Path to this taks's status file
    def status_file_path
      return @status_file_path if @status_file_path
      @status_file_path = File.join task_report_dir, status_file_name
    end

    # @return [String] Path to this task's pid file
    def pid_file_path
      return @pid_file_path if @pid_file_path
      @pid_file_path =  File.join task_pid_dir, daemon_app_name + '.pid'
    end

    # @return [String] Path to this task's report di
    # Creates one if not present
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

    # @return [String] Path to this task's pid directory
    # Creates on if not present
    def task_pid_dir
      return @task_pid_dir if @task_pid_dir
      @task_pid_dir = File.join Deploy::Config[:pid_dir], task_name
      unless File.exists? @task_pid_dir
        require 'fileutils'
        FileUtils.mkdir_p @task_pid_dir
      end
      raise "No pid directory '#{@task_pid_dir}'!" unless File.directory? @task_pid_dir
      @task_pid_dir
    end

    # @return [TrueClass,FalseClass] Does the status file exist?
    def has_status_file?
      File.file? status_file_path
    end

    # delete the status file
    # do nothing if it does not exist
    def remove_status_file
      File.unlink status_file_path if File.file? status_file_path
    end

    # @return [Hash<String>] Return three reports for pre, run and post actions
    def report
      set_process_title "agent: #{task_name} - report"
      pre_report = task.report_read :pre
      run_report = task.report_read :run
      post_report = task.report_read :post
      report = {
          :pre => pre_report,
          :run => run_report,
          :post => post_report,
      }
      set_process_title "agent: #{task_name} - idle"
      report
    end

    # return human readable report of all task's actions
    # @return [String] Human readable report
    def task_report_text
      pre = Deploy::Utils.xunit_to_list(task.report_read(:pre))[:text]
      run = Deploy::Utils.xunit_to_list(task.report_read(:run))[:text]
      post = Deploy::Utils.xunit_to_list(task.report_read(:post))[:text]
      "#{pre}\n#{run}\n#{post}"
    end

    # stop the current task if it's running
    def stop
      set_process_title "agent: #{task_name} - stop"
      running_pid = pid
      begin
        Process.kill 'TERM', running_pid if running_pid
        success = true
      rescue
        success = false
      end
      set_process_title "agent: #{task_name} - idle"
      success
    end

  end # class

end # module
