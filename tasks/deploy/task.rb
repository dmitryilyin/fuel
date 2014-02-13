require 'English'
require 'yaml'

module Deploy

  # this class represents a single task
  class Task

    # @param directory [String]
    def initialize(directory)
      raise "Task directory #{directory} does not exist!" unless directory and File.directory? directory
      directory = File.expand_path directory
      library_dir = Deploy::Config[:library_dir]
      raise "Library directory #{library_dir} does not exist!" unless library_dir and File.directory? library_dir
      task_dir = Deploy::Config[:task_dir]
      raise "Base task directoru #{task_dir} does not exist!" unless task_dir and File.directory? task_dir
      report_dir = Deploy::Config[:report_dir]
      raise "Report directory #{report_dir} is not set!" unless report_dir
      task_file = Deploy::Config[:task_file]
      @task_file = File.join directory, task_file
      @directory = directory
      Deploy::Utils.debug "#{self.class} created with directory #{directory}"
    end

    # name of this task
    # @return [String]
    def name
      return @name if @name
      task_path = directory.clone
      task_path.slice! Deploy::Config[:library_dir]
      task_path.slice! /[\/\.]+/
      task_path.gsub! '/', '::'
      task_path.gsub! ',', ''
      @name = task_path
    end

    # path to this task's directory
    # @return [String]
    def directory
      @directory
    end

    # read tasks's metadata file and return hash contents
    # @return [String]
    def metadata
      return @metadata if @metadata
      task_metadata = YAML.load_file @task_file
      unless task_metadata.is_a? Hash
        task_metadata = {}
      end
      Deploy::Utils.symbolize_hash task_metadata
      default_task_metadata = default_metadata
      Deploy::Utils.symbolize_hash default_task_metadata
      task_metadata = default_task_metadata.merge task_metadata
      @metadata = task_metadata
    end

    # create hash of default metadata values
    # @return [Hash]
    def default_metadata
      {
        :task_comment     => '',
        :task_description => '',
        :pre_plugin       => nil,
        :pre_parameters   => nil,
        :pre_timeout      => nil,
        :pre_autoreport   => false,
        :run_plugin       => nil,
        :run_parameters   => nil,
        :run_timeout      => nil,
        :run_autoreport   => false,
        :post_plugin      => nil,
        :post_parameters  => nil,
        :post_timeout     => nil,
        :post_autoreport  => false,
      }
    end

    # return task's title string
    # @return [String]
    def comment
      return @title if @title
      title = metadata[:task_comment]
      @title = title
    end

    alias :title :comment

    # get path to the report file of the given action
    # @return [String]
    def report_file_path(action = 'run')
      action = action.to_s unless action.is_a? String
      task_report_dir = File.join Deploy::Config[:report_dir], name
      unless File.exists? task_report_dir
        require 'fileutils'
        FileUtils.mkdir_p task_report_dir
      end
      raise "No directory #{task_report_dir} for report!" unless File.directory? task_report_dir
      File.join task_report_dir, action + '.' + Deploy::Config[:report_extension]
    end

    # write report to file
    def report_write(report, action = 'run')
      file = File.open report_file_path(action), 'w'
      raise "Could not open report file #{file} for writing!" unless file
      file.write report
      file.close
    end

    # read report from file and return it as a string
    # @return [String]
    def report_read(action = 'run')
      file = report_file_path action
      raise "No report file #{file}" unless File.exists? file
      File.read file
    end

    # was this task successful? based on report file
    def success?(action = 'run')
      report = Deploy::Utils.xunit_to_list report_read(action)
      report[:errors] == 0
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
      report = Deploy::Utils.xunit_to_list report_read(action)
      puts report[:text]
    end

    # remove the report file
    def report_remove(action = 'run')
      file = report_file_path action
      File.delete file if File.exists? file
    end

    # get pre action plugin for this task
    # @return plugin [Deploy::Action]
    def pre_plugin
      @pre_plugin
    end

    # get run action plugin for this task
    # @return plugin [Deploy::Action]
    def run_plugin
      @run_plugin
    end

    # get run action plugin for this task
    # @return plugin [Deploy::Action]
    def post_plugin
      @post_plugin
    end

    # write report file with success
    # telling that there is no action to do
    # @param action [String]
    def report_no_action(action)
      report = {
          :classname => self.class,
          :name => "No #{action.capitalize}",
      }
      report_write Deploy::Utils.make_xunit(report), action
    end

    # write report file with success
    # telling that action passed without errors
    # @param action [String]
    def report_ok_action(action)
      report = {
          :classname => self.class,
          :name => "Action #{action.capitalize}",
      }
      report_write Deploy::Utils.make_xunit(report), action
    end

    # write report file with failure
    # telling that there were errors during action
    # @param action [String]
    def report_fail_action(action)
      report = {
          :classname => self.class,
          :name => "Action #{action.upcase}",
          :failure => {
              :message => "Action #{action.capitalize} Fail",
              :text => "Execution of action #{action.upcase} have failed!",
          }
      }
      report_write Deploy::Utils.make_xunit(report), action
    end

    # check if this task has pre-deploy test action
    def has_pre?
      !pre_plugin.nil?
    end

    # check if this task has run action
    def has_run?
      !run_plugin.nil?
    end

    # check if this task has post-deploy action
    def has_post?
      !post_plugin.nil?
    end

    # check if this task has given action
    # @param action [String]
    def has_action?(action)
      action = action.to_sym unless action.is_a? Symbol
      case action
        when :pre  then has_post?
        when :run  then has_run?
        when :post then has_post?
        else false
      end
    end

    # run pre-deploy test of this task
    # return exit code if possible
    # @return [Numeric]
    def pre
      unless has_pre?
        report_no_action 'pre'
        return 0
      end
      exit_code = pre_plugin.start
      if metadata[:pre_autoreport]
        if exit_code == 0
          report_ok_action 'pre'
        else
          report_fail_action 'pre'
        end
      end
    end

    # run the actual task code
    # return exit code if possible
    # @return [Numeric]
    def run
      unless has_run?
        report_no_action 'run'
        return 0
      end
      exit_code = run_plugin.start
      if metadata[:run_autoreport]
        if exit_code == 0
          report_ok_action 'run'
        else
          report_fail_action 'run'
        end
      end
    end

    # run the post-deploy test of this task
    # return exit code if possible
    # @return [Numeric]
    def post
      unless has_post?
        report_no_action 'post'
        return 0
      end
      exit_code = run_plugin.post
      if metadata[:post_autoreport]
        if exit_code == 0
          report_ok_action 'post'
        else
          report_fail_action 'post'
        end
      end
    end

    # @param name [String]
    # @return [Class]
    def plugin_matrix(name)
      plugins = {
          :puppet => Deploy::PuppetAction,
          :exec   => Deploy::ExecAction,
          :rspec  => Deploy::RSpecAction,
      }
      plugins[name.to_sym]
    end

    def set_plugins
      if metadata[:pre_plugin]
        plugin = plugin_matrix metadata[:pre_plugin]
        @pre_plugin = plugin.new self, 'pre', metadata[:pre_parameters] if plugin
      end
      if metadata[:run_plugin]
        plugin = plugin_matrix metadata[:run_plugin]
        @run_plugin = plugin.new self, 'run', metadata[:run_parameters] if plugin
      end
      if metadata[:post_plugin]
        plugin = plugin_matrix metadata[:post_plugin]
        @post_plugin = plugin.new self, 'post', metadata[:post_parameters] if plugin
      end
    end

  end # class

end # module
