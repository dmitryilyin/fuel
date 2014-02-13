module Deploy

  # Controlls the process of tasks execution, tests, daemonization, pids and logs #
  class Agent
    def initialize(task_name)
      raise 'Base directory of tasks is not set!' unless Deploy.config[:task_dir] and File.directory? Deploy.config[:task_dir]
      raise 'Report directory is not set!' unless Deploy.config[:report_dir]
      raise 'Pid directory is not set!' unless Deploy.config[:pid_dir]
      task_directory = task_name.gsub '::', '/'
      task_directory = File.join Deploy.config[:task_dir], task_directory
      @task = Deploy::Task.new task_directory
    end

    def task
      @task
    end

  end # class

end # module
