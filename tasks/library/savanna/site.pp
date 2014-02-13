$fuel_settings = parseyaml($astute_settings_yaml)

if !$fuel_settings['savanna'] {
  $savanna_hash={}
} else {
  $savanna_hash = $fuel_settings['savanna']
}

$nodes_hash = $fuel_settings['nodes']
$controller = filter_nodes($nodes_hash,'role','controller')
$controller_node_address = $controller[0]['internal_address']
$use_quantum = $fuel_settings['quantum']

if $savanna_hash['enabled'] {
  class { 'savanna' :
    savanna_api_host          => $controller_node_address,

    savanna_db_password       => $savanna_hash['db_password'],
    savanna_db_host           => $controller_node_address,

    savanna_keystone_host     => $controller_node_address,
    savanna_keystone_user     => 'savanna',
    savanna_keystone_password => $savanna_hash['user_password'],
    savanna_keystone_tenant   => 'services',

    use_neutron               => $use_quantum,
    use_floating_ips          => $fuel_settings['auto_assign_floating_ip'],
  }
}