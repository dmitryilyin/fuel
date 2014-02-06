$fuel_settings = parseyaml($::astute_settings_yaml)
$nova_hash = $fuel_settings['nova']

$nova_user_password = $nova_hash['user_password']
$keystone_host = '127.0.0.1'
$enabled_apis = 'ec2,osapi_compute,osapi_volume'

$nova_rate_limits = {
  'POST' => 1000,
  'POST_SERVERS' => 1000,
  'PUT' => 1000,
  'GET' => 1000,
  'DELETE' => 1000
}

class { 'nova::api':
  enabled           => true,
  admin_password    => $nova_user_password,
  auth_host         => $keystone_host,
  enabled_apis      => $enabled_apis,
  nova_rate_limits  => $nova_rate_limits,
  cinder            => false,
}

exec { 'post-nova_config':
  command => '/bin/echo "Nova config has changed"',
  refreshonly => true,
}
