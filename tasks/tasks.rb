require 'yaml'
require 'English'

module Tasks
  def self.parse_config(config_file = 'config.yaml')
    raise 'No config file name!' unless config_file
    @tasks_dir = File.expand_path File.dirname(__FILE__)
    config_path = File.join @tasks_dir, config_file
    @config = YAML.load_file(config_path)
    raise 'Could not parse config file' unless @config
  end

  def self.config
    self.parse_config unless @config
    @config
  end

  def self.read_xunit(file_name)
    require 'rubygems'
    require 'rexml/document'
    include REXML

    raise 'No file given!' unless file_name
    xml = REXML::Document.new File.open file_name, 'r'
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

  class Task
    def initialize(directory)
      raise 'Task directory does not exist!' unless directory and File.directory? directory
      raise 'Base directory of tasks is not set!' unless Tasks.config[:task_dir] and File.directory? Tasks.config[:task_dir]
      raise 'Report directory is not set!' unless Tasks.config[:report_dir]
      @directory = directory
    end

    def name
      return @name if @name
      task_path = directory.clone
      task_path.slice! Tasks.config[:task_dir]
      task_path.slice! /[\/\.]+/
      task_path.gsub! '/', '::'
      @name = task_path
    end

    def directory
      @directory
    end

    def make_xunit(testcases)
      raise 'No testcases! There should be at least one.' unless testcases.instance_of? Array and testcases.any?
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

    def report_file_path(action = 'run')
      task_report_dir = File.join Tasks.config[:report_dir], name
      unless File.exists? task_report_dir
        require 'fileutils'
        FileUtils.mkdir_p task_report_dir
      end
      raise "No directory #{task_report_dir} for report!" unless File.directory? task_report_dir
      extension = Tasks.config[:report_extension] ? ".#{Tasks.config[:report_extension]}" : ''
      File.join task_report_dir, action + extension
    end

    def write_report(report, action = 'run')
      file = File.open report_file_path(action), 'w'
      raise "Could not open report file #{file} for writing!" unless file
      file.write report
      file.close
    end

    def report_read(action = 'run')
      file = report_file_path action
      raise "No report file #{file}" unless File.exists? file
      errors, report = Tasks.read_xunit file
      puts report
      errors
    end

    def report_success(action = 'run')
      file = report_file_path action
      raise "No report file #{file}" unless File.exists? file
      errors, report = Tasks.read_xunit file
      errors == 0
    end

    def report_raw(action = 'run')
      file = report_file_path action
      raise "No report file #{file}" unless File.exists? file
      report = File.read file
      puts report
    end

    def report_remove(action = 'run')
      file = report_file_path action
      File.delete file if File.exists? file
    end

    def run
      puppet_manifest = File.join directory, Tasks.config[:puppet_manifest]
      unless File.exists? puppet_manifest
        report = [ { :classname => 'Puppet::Apply', :name => 'Puppet Apply',
          :failure => { :message => 'Manifest not found!', :text => "No Puppet manifest: #{puppet_manifest}" }
        } ]
        write_report make_xunit report
        return 1
      end
      system "puppet apply --detailed-exitcodes -vd #{puppet_manifest}"
      error_code = $CHILD_STATUS.exitstatus
      if [0,2].include? error_code
        report = [ { :classname => 'Puppet::Apply', :name => 'Puppet Apply', } ]
      else
        report = [ { :classname => 'Puppet::Apply', :name => 'Puppet Apply',
          :failure => { :message => 'Puppet Error', :text => "Puppet manifest #{puppet_manifest} returned error code #{error_code}" }
        } ]
      end
      write_report make_xunit report
      error_code
    end

    def pre
      action = 'pre'
      spec_file = Tasks.config[:spec_pre]
      Dir.chdir directory or raise "Could no change directory to #{directory}"
      unless File.exists? spec_file
        report = [ { :classname => 'Task::Test::Pre-deploy', :name => 'No Pre-deploy Test', } ]
        write_report make_xunit(report), action
        return 1
      end
      system "rspec -f RspecJunitFormatter --out \"#{report_file_path action}\" \"#{spec_file}\""
      $CHILD_STATUS.exitstatus
    end

    def post
      action = 'post'
      spec_file = Tasks.config[:spec_post]
      Dir.chdir directory or raise "Could no change directory to #{directory}"
      unless File.exists? spec_file
        report = [ { :classname => 'Task::Test::Post-deploy', :name => 'No Post-deploy Test', } ]
        write_report make_xunit(report), action
        return 1
      end
      system "rspec -f RspecJunitFormatter --out \"#{report_file_path action}\" \"#{spec_file}\""
      $CHILD_STATUS.exitstatus
    end

  end

end
