$fuel_settings = parseyaml($::astute_settings_yaml)

$keystone_hash = $fuel_settings['keystone']

$db_user     = 'keystone'
$db_password = $keystone_hash['db_password']
$db_name     = 'keystone'

mysql::account { $db_name :
  user     => $db_user,
  password => $db_password,
  allowed  => ['127.0.0.1', '%'],
}
