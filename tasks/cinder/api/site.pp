$fuel_settings = parseyaml($::astute_settings_yaml)
$rabbit_hash   = $fuel_settings['rabbit']
$nodes_hash    = $fuel_settings['nodes']
$cinder_hash   = $fuel_settings['cinder']

$rabbit_password = $rabbit_hash['password']

$controller = filter_nodes($nodes_hash,'role','controller')
$controller_node_address = $controller[0]['internal_address']
$controller_node_public  = $controller[0]['public_address']

$cinder_user_password = $cinder_hash['user_password']

$cinder_rate_limits = {
  'POST' => 1000,
  'POST_SERVERS' => 1000,
  'PUT' => 1000,
  'GET' => 1000,
  'DELETE' => 1000
}

class { 'cinder::api' :
  package_ensure     => 'present',
  keystone_auth_host => $controller_node_address,
  keystone_password  => $cinder_user_password,
  cinder_rate_limits => $cinder_rate_limits
}
