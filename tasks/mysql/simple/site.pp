$fuel_settings = parseyaml($astute_settings_yaml)
$keystone_hash = $fuel_settings['keystone']

$db_user     = 'keystone'
$db_password = $keystone_hash['db_password']
$db_name     = 'keystone'

$use_syslog = true

class { 'mysql::server' :
  config_hash => {
    'bind_address'  => '0.0.0.0',
  },
  use_syslog => $use_syslog,
}

class { 'mysql::server::account_security': }

class { 'keystone::db::mysql':
  user          => $db_user,
  password      => $db_password,
  dbname        => $db_name,
  allowed_hosts => ['localhost', '%'],
  charset       => 'utf8',
}