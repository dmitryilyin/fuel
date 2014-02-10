$fuel_settings = parseyaml($::astute_settings_yaml)
$cinder_hash   = $fuel_settings['cinder']

$db_password = $cinder_hash['db_password']
$db_user     = 'cinder'
$db_dbname   = 'cinder'
$db_host     = $controller_node_address
 
mysql::account { $db_name :
  user     => $db_user,
  password => $db_password,
  allowed  => ['127.0.0.1', '%'],
}
