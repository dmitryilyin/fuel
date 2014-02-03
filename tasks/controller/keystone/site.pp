$fuel_settings = parseyaml($astute_settings_yaml)

$verbose = true
$debug   = $fuel_settings['debug']

$keystone_hash = $fuel_settings['keystone']
$access_hash   = $fuel_settings['access']

$admin_token = $keystone_hash['admin_token']
$use_syslog  = $fuel_settings['use_syslog']

$db_user     = 'keystone'
$db_password = $keystone_hash['db_password']
$db_host     = '127.0.0.1'
$db_name     = 'keystone'

$admin_email    = $access_hash['email']
$admin_user     = $access_hash['user']
$admin_password = $access_hash['password']
$admin_tenant   = $access_hash['tenant']

$sql_conn = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"

class { 'keystone' :
  verbose        => $verbose,
  debug          => $debug,
  admin_token    => $admin_token,
  sql_connection => $sql_conn,
  use_syslog     => $use_syslog,
}

class { 'keystone::roles::admin' :
  admin        => $admin_user,
  email        => $admin_email,
  password     => $admin_password,
  admin_tenant => $admin_tenant,
}

class { 'keystone::endpoint' :
  public_address   => $public_address,
  admin_address    => $admin_real,
  internal_address => $internal_real,
}