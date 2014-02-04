$fuel_settings = parseyaml($astute_settings_yaml)
$keystone_hash = $fuel_settings['keystone']

$db_user     = 'keystone'
$db_password = $keystone_hash['db_password']
$db_name     = 'keystone'

class { 'keystone::db::mysql':
  user          => $db_user,
  password      => $db_password,
  dbname        => $db_name,
  allowed_hosts => ['127.0.0.1', '%'],
}