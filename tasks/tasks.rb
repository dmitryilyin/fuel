require 'yaml'
require 'English'

module Tasks

  ### Config functions ###

  # load default config values if they
  # are not set in config file
  def self.config_defaults(defaults_hash)
    raise 'Defaults is not a Hash!' unless defaults_hash.is_a? Hash
    defaults_hash.each do |k, v|
      k = k.to_sym
      @config[k] = v unless @config[k]
    end
  end

  # a set of default config values
  def self.set_config_defaults
    defaults_hash = {
      :task_dir         => '/etc/puppet/tasks',
      :module_dir       => '/etc/puppet/modules',
      :puppet_options   => '',
      :report_format    => 'xunit',
      :report_extension => '',
      :report_dir       => '/var/log/tasks',
      :pid_dir          => '/var/run/tasks',
      :puppet_manifest  => 'site.pp',
      :spec_pre         => 'spec/pre_spec.rb',
      :spec_post        => 'spec/post_spec.rb',
      :task_file        => 'task.md',
      :api_file         => 'api.rb',
    }
    config_defaults defaults_hash
  end

  # this module method loads task config file
  def self.parse_config(config_file = 'config.yaml')
    raise 'No config file name!' unless config_file
    @tasks_dir = File.expand_path File.dirname(__FILE__)
    config_path = File.join @tasks_dir, config_file
    @config = YAML.load_file(config_path)
    raise 'Could not parse config file' unless @config
    self.set_config_defaults
  end

  # this method loads and returns task config with mnomoisation
  def self.config
    self.parse_config unless @config
    @config
  end

  ### Utils functions ###

  # this method parses xunit report to human readable form
  def self.xunit_to_list(xunit)
    require 'rubygems'
    require 'rexml/document'
    include REXML

    xml = REXML::Document.new xunit
    raise 'Could not parse file!' unless xml

    text = ''
    testsuite = xml.root.elements['/testsuite']
    errors = testsuite.attributes['failures'].to_i
    testcases = xml.root.elements.to_a('testcase')

    testcases.each do |tc|
      success = true
      message = ''
      failures = tc.elements.to_a('failure')
      if failures.any?
        success = false
        message = failures.first.texts.join.gsub(/\s+/,' ')
      end
      text += "#{tc.attributes['name']} | #{success ? 'OK' : 'FAIL'} | #{message}\n"
    end

    text += '-' * 20 + "\n"
    text += "Errors: #{errors}\n"
    return errors, text
  end

  # this method parses json report to human readable form
  def self.json_to_list(json)
    #  TODO implement
    return 0, ''
  end

  # creates task api symlinks in a directory
  # to initialize it as standard task
  def self.create_api_links(task_dir = nil, api = nil, actions = %w(pre run post))
    api = File.join Tasks.config[:task_dir], Tasks.config[:api_file] unless api
    task_dir = '.' unless task_dir
    actions.each do |a|
      symlink = File.join task_dir, a
      puts "#{api} => #{symlink}"
      File.unlink symlink if File.exists? symlink or File.symlink? symlink
      File.symlink api, symlink unless File.exists? symlink
      raise "#{symlink} is not a symlink!" unless File.symlink? symlink
    end
  end

  # walk across the folders in the task dir and create api links
  # for every folder that looks like task
  def self.create_all_task_links (task_file_check = true, puppet_manifest_check = true)
    require 'find'
    raise 'No task dir!' unless Tasks.config[:task_dir] and File.directory? Tasks.config[:task_dir]
    Find.find(Tasks.config[:task_dir] + '/') do |path|
      next unless path.end_with? Tasks.config[:task_file] or !task_file_check
      task_dir = File.dirname path
      manifest = File.join task_dir, Tasks.config[:puppet_manifest]
      next unless File.exists? manifest or !puppet_manifest_check
      self.create_api_links task_dir
    end
  end

  # removes all links to taks api in entire task_dir
  def self.remove_all_task_links
    require 'find'
    raise 'No task dir!' unless Tasks.config[:task_dir] and File.directory? Tasks.config[:task_dir]
    Find.find(Tasks.config[:task_dir] + '/') do |path|
      actions = %w(pre run post deploy)
      next unless actions.select { |a| path.end_with?('/' + a) }.any? and File.symlink? path
      puts "X-> #{path}"
      File.unlink path
    end
  end

  # find tasks without spec
  def self.check_if_spec_present
    require 'find'
    raise 'No task dir!' unless Tasks.config[:task_dir] and File.directory? Tasks.config[:task_dir]
    Find.find(Tasks.config[:task_dir] + '/') do |path|
      if path.end_with? '/run'
        task_dir = File.dirname path
        task = Tasks::Task.new task_dir
        puts "No pre-deploy test in task #{task.name} at #{task.directory}" unless task.has_pre_spec?
        puts "No post-deploy test in task #{task.name} at #{task.directory}" unless task.has_post_spec?
      end
    end
  end

  # print a line of the task list
  def self.print_task_line(task, name_length)
    line = ''
    line += task.name.to_s.ljust name_length if task.name
    line += task.comment.to_s if task.comment
    puts line unless line.empty?
  end

# print the entire list of tasks
  def self.print_tasks_list(tasks)
    raise 'Tasks list should be Array!' unless tasks.is_a? Array
    return nil unless tasks.any?
    max_length = tasks.inject 0 do |ml, t|
      len = t.name.length
      ml = len > ml ? len : ml
    end
    tasks.each { |t| self.print_task_line t, max_length + 1 }
  end

  ### Task Class ###

  # Works with a single tasks, its actions and variables #

  # this class represents a single task
  class Task
    def initialize(directory)
      raise 'Task directory does not exist!' unless directory and File.directory? directory
      raise 'Base directory of tasks is not set!' unless Tasks.config[:task_dir] and File.directory? Tasks.config[:task_dir]
      raise 'Report directory is not set!' unless Tasks.config[:report_dir]
      @readme_file = File.join directory, Tasks.config[:task_file]
      @directory = directory
    end

    # name of this task
    def name
      return @name if @name
      task_path = directory.clone
      task_path.slice! Tasks.config[:task_dir]
      task_path.slice! /[\/\.]+/
      task_path.gsub! '/', '::'
      task_path.gsub! ',', ''
      @name = task_path
    end

    # path to this task's directory
    def directory
      @directory
    end

    # show the task's description file
    def readme
      return nil unless File.exists? @readme_file
      begin
        file = File.open @readme_file, 'r'
        readme = file.read
        file.close
      rescue
        return nil
      end
      readme
    end

    # return task's title string
    def title
      return @title if @title
      return nil unless File.exists? @readme_file
      begin
        file = File.open @readme_file, 'r'
        title = file.readline.chomp
        file.close
      rescue
        return nil
      end
      @title = title
    end

    # generate xunit xml report
    def make_xunit(testcases)
      testcases = [testcases] unless testcases.kind_of? Array
      raise 'No testcases! There should be at least one.' unless testcases.any?
      tests = testcases.length
      failures = testcases.select { |tc| tc[:failure] }.length
      errors = 0
      require 'time'
      timestamp = Time.now.iso8601
      time = testcases.inject(0.0) { |t,tc| t += tc[:time] || 0.0 }
      xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      xml += "<testsuite tests=\"#{tests}\" failures=\"#{failures}\" errors=\"#{errors}\" timestamp=\"#{timestamp}\" time=\"#{time}\">\n"
      testcases.each do |tc|
        raise "Task #{tc.inspect} has no classname" unless tc[:classname]
        xml += "<testcase classname=\"#{tc[:classname]}\" time=\"#{tc[:time] || 0.0}\" name=\"#{tc[:name] || tc[:classname]}\">\n"
        if tc[:failure]
          raise "Task #{tc.inspect} has no failure message" unless tc[:failure][:message]
          xml += "<failure type=\"#{tc[:failure][:type] || 'Task::Error'}\" message=\"#{tc[:failure][:message]}\">\n"
          xml += "<![CDATA[#{tc[:failure][:text] || tc[:failure][:message]}]]>\n"
          xml += "</failure>\n"
        end
        xml += "</testcase>\n"
      end
      xml += "</testsuite>\n"
    end

    # get path to the report file of the given action
    def report_file_path(action = 'run')
      action = action.to_s unless action.is_a? String
      task_report_dir = File.join Tasks.config[:report_dir], name
      unless File.exists? task_report_dir
        require 'fileutils'
        FileUtils.mkdir_p task_report_dir
      end
      raise "No directory #{task_report_dir} for report!" unless File.directory? task_report_dir
      File.join task_report_dir, action + '.' + Tasks.config[:report_extension]
    end

    # write report to file
    def write_report(report, action = 'run')
      file = File.open report_file_path(action), 'w'
      raise "Could not open report file #{file} for writing!" unless file
      file.write report
      file.close
    end

    # read report from file and return it as a string
    def report_read(action = 'run')
      file = report_file_path action
      raise "No report file #{file}" unless File.exists? file
      File.read file
    end

    # was this task successful? based on report file
    def success?(action = 'run')
      errors, report = Tasks.xunit_to_list report_read(action)
      errors == 0
    end

    # did this task fail?
    def fail?(action = 'run')
      !success? action
    end

    # read report from file and output it in a raw form
    def report_raw(action = 'run')
      puts report_read(action)
    end

    # read report and output it in human-readable form
    def report_output(action = 'run')
      errors, report = Tasks.xunit_to_list report_read(action)
      puts report
    end

    # remove the report file
    def report_remove(action = 'run')
      file = report_file_path action
      File.delete file if File.exists? file
    end

    # run the task's Puppet payload
    def run
      puppet_manifest = File.join directory, Tasks.config[:puppet_manifest]
      unless File.exists? puppet_manifest
        report = {
          :classname => 'Puppet::Apply',
          :name => 'Puppet Apply',
          :failure => {
            :message => 'Manifest not found!',
            :text => "No Puppet manifest: #{puppet_manifest}"
          }
        }
        write_report make_xunit report
        return 1
      end
      puppet_command = 'puppet apply --detailed-exitcodes'
      puppet_command += " --modulepath=\"#{Tasks.config[:module_dir]}\"" if Tasks.config[:module_dir]
      puppet_command += " #{Tasks.config[:puppet_options]}" if Tasks.config[:puppet_options]
      system "#{puppet_command} #{puppet_manifest}"
      error_code = $CHILD_STATUS.exitstatus
      if [0,2].include? error_code
        report = {
          :classname => 'Puppet::Apply',
          :name => 'Puppet Apply',
        }
      else
        report = {
          :classname => 'Puppet::Apply',
          :name => 'Puppet Apply',
          :failure => {
            :message => 'Puppet Error',
            :text => "Puppet manifest #{puppet_manifest} returned error code #{error_code}"
          }
        }
      end
      write_report make_xunit report
      error_code
    end

    # does this task have pre-deploy spec?
    def has_pre_spec?
      spec_file = File.join directory, Tasks.config[:spec_pre]
      File.exists? spec_file
    end

    # does this task have post-deploy spec?
    def has_post_spec?
      spec_file = File.join directory, Tasks.config[:spec_post]
      File.exists? spec_file
    end

    # run pre-deploymnet serverspec test
    def pre
      action = 'pre'
      spec_file = Tasks.config[:spec_pre]
      Dir.chdir directory or raise "Could no change directory to #{directory}"
      unless File.exists? spec_file
        report = {
          :classname => 'Task::Test::Pre-deploy',
          :name => 'No Pre-deploy Test',
        }
        write_report make_xunit(report), action
        return 1
      end
      system "rspec -f RspecJunitFormatter --out \"#{report_file_path action}\" \"#{spec_file}\""
      $CHILD_STATUS.exitstatus
    end

    # run post-deployment serverspec test
    def post
      action = 'post'
      spec_file = Tasks.config[:spec_post]
      Dir.chdir directory or raise "Could no change directory to #{directory}"
      unless File.exists? spec_file
        report = {
          :classname => 'Task::Test::Post-deploy',
          :name => 'No Post-deploy Test',
        }
        write_report make_xunit(report), action
        return 1
      end
      system "rspec -f RspecJunitFormatter --out \"#{report_file_path action}\" \"#{spec_file}\""
      $CHILD_STATUS.exitstatus
    end

  end

  ### Agent class ###

  # Controlls the process of tasks execution, tests, daemonization, pids and logs #

  class Agent
    def initialize(task_name)
      raise 'Base directory of tasks is not set!' unless Tasks.config[:task_dir] and File.directory? Tasks.config[:task_dir]
      raise 'Report directory is not set!' unless Tasks.config[:report_dir]
      raise 'Pid directory is not set!' unless Tasks.config[:pid_dir]
      task_directory = task_name.gsub '::', '/'
      task_directory = File.join Tasks.config[:task_dir], task_directory
      @task = Tasks::Task.new task_directory
    end

    def task
      @task
    end


  end

end
