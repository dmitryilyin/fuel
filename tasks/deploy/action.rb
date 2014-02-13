module Deploy
  # Abstract action plugin
  # @abstract
  class Action
    # @param task [Deploy::Task]
    # @param action [String]
    def initialize(task, action)
      raise "Action Plugin should be given a task when created but got #{task.class}" unless task.is_a? Deploy::Task
      @task = task
      @action = action
    end

    # return the task this action is attached to
    # @return [Deploy::Task]
    def task
      @task
    end

    # return the action set for this plugin
    # @return [String]
    def action
      @action
    end

    # run the task code
    # return exit code if possible
    # @return [Fixnum]
    def start
      raise 'This is an abstract action and should be inherited and implemented!'
    end

    def report_write(report)
      task.report_write report, action
    end

    def report_read
      task.report_read action
    end

    def report_output
      task.report_output action
    end

    def report_remove
      task.report_remove action
    end

  end
end
