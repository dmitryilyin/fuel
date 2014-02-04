$fuel_settings = parseyaml($astute_settings_yaml)

$nodes_hash  = $fuel_settings['nodes']
$controller  = filter_nodes($nodes_hash,'role','controller')
$controller_node_address = $controller[0]['internal_address']
$controller_node_public  = $controller[0]['public_address']

class { 'keystone::endpoint' :
  public_address   => $controller_node_public,
  admin_address    => $controller_node_address,
  internal_address => $controller_node_address,
}