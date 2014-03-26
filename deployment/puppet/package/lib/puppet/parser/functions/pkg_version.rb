Puppet::Parser::Functions::newfunction(:pkg_version, :type => :rvalue,
:doc => <<-EOS
Take package version from $fuel_settings or return the default value.
EOS
) do |argv|
  name = argv[0]
  settings = lookupvar('fuel_settings')
  default = 'installed'
  unless settings.is_a? Hash and settings['versions'].is_a? Hash
    warn '$fuel_settings[\'versions\'] is not a correct structure!'
    return default
  end
  version = settings['versions'][name]
  return version if version
  return default
end
