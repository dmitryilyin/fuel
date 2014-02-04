$fuel_settings = parseyaml($astute_settings_yaml)

$access_hash   = $fuel_settings['access']

$admin_email    = $access_hash['email']
$admin_user     = $access_hash['user']
$admin_password = $access_hash['password']
$admin_tenant   = $access_hash['tenant']

class { 'keystone::roles::admin' :
  admin        => $admin_user,
  email        => $admin_email,
  password     => $admin_password,
  admin_tenant => $admin_tenant,
}