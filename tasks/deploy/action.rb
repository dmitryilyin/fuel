module Deploy
  # Abstract action plugin
  # @abstract
  class Action
    # @param task [Deploy::Task]
    # @param action [Symbol]
    def initialize(task, action)
      raise "Action Plugin should be given a task when created but got #{task.class}!" unless task.is_a? Deploy::Task
      @task = task
      @action = action
      Deploy::Utils.debug "Created #{self.class} with action #{@action} for task #{task.name}"
    end

    # return the task this action is attached to
    # @return [Deploy::Task]
    def task
      @task
    end

    # return the action set for this plugin
    # @return [Symbol]
    def action
      @action
    end

    # run the task code
    # return exit code if possible
    # @return [Fixnum]
    def start
      raise 'This is an abstract action and should be inherited and implemented!'
    end

    # write the report to file
    # it's a carred method from Deploy::Task
    # @param report [String]
    def report_write(report)
      task.report_write report, action
    end

    # read the report file and return it as a string
    # it's a carred method from Deploy::Task
    # @return [String]
    def report_read
      task.report_read action
    end

    # read the report file and output it
    # it's a carred methos from Deploy::Task
    def report_output
      task.report_output action
    end

    # remove the report file
    # it's a carred method from Deploy::Task
    def report_remove
      task.report_remove action
    end

    # return the path to report file of this action
    # it's a carred method from Deploy::Task
    # @return [String]
    def report_file_path
      task.report_file_path action
    end

  end
end
