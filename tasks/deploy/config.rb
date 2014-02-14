require 'yaml'

module Deploy

  # deploymnet configuration class #
  class Config

    # a set of default config values
    # @return [Hash]
    def self.default_config
      {
          :task_dir => '/etc/puppet/tasks',
          :library_dir => '/etc/puppet/tasks/library',
          :module_dir => '/etc/puppet/modules',
          :puppet_options => '',
          :report_format => 'xunit',
          :report_extension => '',
          :report_dir => '/var/log/tasks',
          :pid_dir => '/var/run/tasks',
          :puppet_manifest => 'site.pp',
          :spec_pre => 'spec/pre_spec.rb',
          :spec_post => 'spec/post_spec.rb',
          :task_file => 'task.yaml',
          :api_file => 'taskapi.rb',
          :debug => false,
      }
    end

    # this module method loads task config file
    # and sets default values for values not present
    # in config file
    # @return [Hash]
    def self.config
      return @config if @config
      script_dir = File.dirname __FILE__
      config_file = 'config.yaml'
      config_path = File.join script_dir, '..', config_file
      config = YAML.load_file(config_path)
      config = {} unless config.is_a? Hash
      @config = self.default_config.merge config
    end

    # makes possible to access config like this
    # Deploy::Config.task_dir
    def self.method_missing(key)
      self.config[key]
    end

    # makes possible to access config like this
    # Deploy::Config[:task_dir]
    def self.[](key)
      self.config[key]
    end

  end # class

end # module
