require 'English'

# run puppet manifest as a task
class Deploy::PuppetAction < Deploy::Action

  # @param task [Deploy::Task]
  # @param action [String]
  # @param manifest [String]
  def initialize(task, action, manifest = nil)
    @file = manifest
    @file = Deploy::Config[:puppet_manifest] unless @file
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

  def exists?
    File.exists? path and File.readable? path
  end

  def report_no
    report = {
      :classname => 'Deploy::PuppetAction',
      :name => 'No Manifest',
    }
    report_write Deploy::Utils.make_xunit report
  end

  def report_ok
    report = {
      :classname => 'Puppet:PuppetAction',
      :name => 'Puppet Apply',
    }
    report_write Deploy::Utils.make_xunit report
  end

  def report_fail
    report = {
      :classname => 'Deploy::PuppetAction',
      :name => 'Puppet Apply',
      :failure => {
          :message => 'Puppet Error',
          :text => "Puppet manifest #{path} apply have failed!"
      }
    }
    report_write Deploy::Utils.make_xunit report
  end

  def puppet_command
    puppet_command = 'puppet apply --detailed-exitcodes'
    puppet_command += " --modulepath=\"#{Deploy::Config[:module_dir]}\"" if Deploy::Config[:module_dir]
    puppet_command += " #{Deploy::Config[:puppet_options]}" if Deploy::Config[:puppet_options]
    puppet_command
  end

  # @return[Fixnum]
  def start
    unless exists?
      report_no
      return 0
    end
    system "#{puppet_command} #{path}"
    error_code = $CHILD_STATUS.exitstatus
    if [0,2].include? error_code
      report_ok
    else
      report_fail
    end
    error_code
  end

end
