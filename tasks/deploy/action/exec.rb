require 'English'

# run the custom executable as a task
class Deploy::ExecAction < Deploy::Action

  # @param task [Deploy::Task]
  # @param action [String]
  # @param file [String]
  def initialize(task, action, file)
    @file = file
    super task, action
  end

  # return this action's file name
  # @return [String]
  def file
    @file
  end

  # return the full path to this action's file
  # @return [String]
  def path
    path = File.expand_path File.join task.directory, file
    @path = path
  end

  # ensure that action file is executable
  # make it if not
  def ensure_executable
    File.chmod 0755, path unless File.stat(path).executable?
  end

  # is there an action file for ths action?
  def exists?
    File.file? path and File.readable? path
  end

  # write the report file with success
  # telling that there is no action file
  # for this action
  def report_no
    report = {
        :classname => self.class,
        :name => "No #{action} Exec",
    }
    report_write Deploy::Utils.make_xunit report
  end

  # write the report file with success
  # telling that exec was successful
  def report_ok
    report = {
        :classname => self.class,
        :name => "Exec #{action}",
    }
    report_write Deploy::Utils.make_xunit report
  end

  # write the report file with error
  # telling that exec have failed
  def report_fail
    report = {
        :classname => self.class,
        :name => "Exec #{action}",
        :failure => {
            :message => "Exec #{action} Failed",
            :text => "Exec '#{path}' have failed!"
        }
    }
    report_write Deploy::Utils.make_xunit report
  end

  # run the exec action
  # @return [Fixnum]
  def call
    Deploy::Utils.debug "Start #{self.class} with action '#{action.to_s}' and '#{path}' file"
    unless exists?
      report_no
      return 0
    end
    ensure_executable
    report_remove
    system path
    exit_code = $CHILD_STATUS.exitstatus
    if exit_code == 0
      report_ok
    else
      report_fail
    end
    exit_code
  end

end
