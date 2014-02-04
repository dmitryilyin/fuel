$fuel_settings = parseyaml($astute_settings_yaml)

$verbose = true
$debug   = $fuel_settings['debug']

$keystone_hash = $fuel_settings['keystone']

$admin_token = $keystone_hash['admin_token']
$use_syslog  = $fuel_settings['use_syslog']

$db_user     = 'keystone'
$db_password = $keystone_hash['db_password']
$db_host     = '127.0.0.1'
$db_name     = 'keystone'

$sql_conn = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"

class { 'keystone' :
  verbose        => $verbose,
  debug          => $debug,
  admin_token    => $admin_token,
  sql_connection => $sql_conn,
  use_syslog     => $use_syslog,
}



