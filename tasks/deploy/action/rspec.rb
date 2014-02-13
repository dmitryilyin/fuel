require 'English'

# run rspec as a test task
class Deploy::RSpecAction < Deploy::Action

  # @param task [Deploy::Task]
  # @param action [String]
  # @param spec [String]
  def initialize(task, action, spec = nil)
    @file = spec
    @file = Deploy::Config[:puppet_manifest] unless @file
    super task, action
  end

  # return the name of this action's file
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

  # is there a spec file for this action?
  def exists?
    File.exists? path and File.readable? path
  end

  # write the report file with success
  # telling that there is no spec file
  # for this action
  def report_no
    report = {
        :classname => self.class,
        :name => "No #{action.to_s.spec} Spec",
    }
    report_write Deploy::Utils.make_xunit report
  end

  # make the rspec command line
  # @return [String]
  def rspec_command
    rspec_command = 'rspec'
    report_format = Deploy::Config[:report_format]
    case report_format
      when 'xunit' then rspec_command += ' -f RspecJunitFormatter'
      when 'json'  then rspec_command += ' -f json'
      when 'text'  then rspec_command += ' -f doc'
      else raise "Report format #{report_format} is not supported!"
    end
    rspec_command + " --out \"#{report_file_path}\""
  end

  # run the rspec test
  # @return[Fixnum]
  def start
    unless exists?
      report_no
      return 0
    end
    system "#{rspec_command} #{path}"
    $CHILD_STATUS.exitstatus
  end

end
