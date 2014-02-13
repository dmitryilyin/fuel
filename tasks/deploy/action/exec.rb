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

  # @return [String]
  def file
    @file
  end

  # @return [String]
  def path
    path = File.expand_path File.join task.directory, file
    @path = path
  end

  def ensure_executable
    File.chmod 0755, path unless File.stat(path).executable?
  end

  def exists?
    File.file? path and File.readable? path
  end

  def report_no
    report = {
        :classname => 'Deploy::ExecAction',
        :name => 'No Script',
    }
    report_write Deploy::Utils.make_xunit report
  end

  def report_ok
    report = {
        :classname => 'Deploy::ExecAction',
        :name => 'Script Run',
    }
    report_write Deploy::Utils.make_xunit report
  end

  def report_fail
    report = {
        :classname => 'Deploy::ExecAction',
        :name => 'Script Run',
        :failure => {
            :message => 'Script Failed',
            :text => "Script #{path} have failed!"
        }
    }
    report_write Deploy::Utils.make_xunit report
  end

  # @return [Fixnum]
  def start
    unless exists?
      report_no
      return 0
    end
    ensure_executable
    system path
    error_code = $CHILD_STATUS.exitstatus
    if error_code == 0
      report_ok
    else
      report_fail
    end
    error_code
  end

end
