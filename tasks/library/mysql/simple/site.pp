$fuel_settings = parseyaml($::astute_settings_yaml)

class { 'mysql::server' :
  config_hash => {
    'bind_address'  => '0.0.0.0',
  },
  use_syslog => false,
}

class { 'mysql::server::account_security': }
