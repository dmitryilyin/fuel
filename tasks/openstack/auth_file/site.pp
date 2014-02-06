$fuel_settings = parseyaml($::astute_settings_yaml)

$access_hash   = $fuel_settings['access']
$keystone_hash = $fuel_settings['keystone']
$nodes_hash    = $fuel_settings['nodes']

$controller = filter_nodes($nodes_hash,'role','controller')
$controller_node_address = $controller[0]['internal_address']

class { 'openstack::auth_file':
  admin_user           => $access_hash['user'],
  admin_password       => $access_hash['password'],
  keystone_admin_token => $keystone_hash['admin_token'],
  admin_tenant         => $access_hash['tenant'],
  controller_node      => $controller_node_address,
}
