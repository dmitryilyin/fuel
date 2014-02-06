$fuel_settings = parseyaml($::astute_settings_yaml)

$nova_hash = $fuel_settings['nova']

$db_user     = 'nova'
$db_password = $nova_hash['db_password']
$db_name     = 'nova'

mysql::account { $db_name :
  user     => $db_user,
  password => $db_password,
  allowed  => ['127.0.0.1', '%'],
}
