$use_syslog = true

class { 'mysql::server' :
  config_hash => {
    'bind_address'  => '0.0.0.0',
  },
  use_syslog => $use_syslog,
}

class { 'mysql::server::account_security': }
