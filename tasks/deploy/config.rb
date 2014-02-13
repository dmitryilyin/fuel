require 'yaml'

module Deploy

  # deploymnet configuration class #
  class Config

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
          :library_dir      => '/etc/puppet/tasks/library',
          :module_dir       => '/etc/puppet/modules',
          :puppet_options   => '',
          :report_format    => 'xunit',
          :report_extension => '',
          :report_dir       => '/var/log/tasks',
          :pid_dir          => '/var/run/tasks',
          :puppet_manifest  => 'site.pp',
          :spec_pre         => 'spec/pre_spec.rb',
          :spec_post        => 'spec/post_spec.rb',
          :task_file        => 'task.yaml',
          :api_file         => 'api.rb',
          :debug            => true,
      }
      config_defaults defaults_hash
    end

    # this module method loads task config file
    def self.parse_config(config_path = nil)
      script_dir = File.dirname __FILE__
      config_file = 'config.yaml'
      config_path = File.join script_dir, '..', config_file unless config_path
      @config = YAML.load_file(config_path)
      raise 'Could not parse config file' unless @config
      self.set_config_defaults
    end

    # this method loads and returns task config with mnomoisation
    # @return [Hash]
    def self.config
      self.parse_config unless @config
      @config
    end

    def self.method_missing(key)
      self.config[key]
    end

    def self.[](key)
      self.config[key]
    end

  end # class

end # module
