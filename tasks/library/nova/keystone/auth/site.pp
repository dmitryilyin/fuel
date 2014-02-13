$fuel_settings = parseyaml($::astute_settings_yaml)

$nodes_hash = $fuel_settings['nodes']
$nova_hash  = $fuel_settings['nova']

$controller  = filter_nodes($nodes_hash,'role','controller')
$controller_node_address = $controller[0]['internal_address']
$controller_node_public  = $controller[0]['public_address']

$nova_user_password = $nova_hash['user_password']

class { 'nova::keystone::auth':
  auth_name        => 'nova',
  password         => $nova_user_password,
  public_address   => $controller_node_public,
  admin_address    => $controller_node_address,
  internal_address => $controller_node_address,
  cinder           => true,
}
