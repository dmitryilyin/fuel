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

if $murano_hash['enabled'] {
  class { 'murano' :
    murano_api_host          => $controller_node_address,

    murano_rabbit_host       => $controller_node_public,
    murano_rabbit_login      => 'murano',
    murano_rabbit_password   => $heat_hash['rabbit_password'],

    murano_db_host           => $controller_node_address,
    murano_db_password       => $murano_hash['db_password'],

    murano_keystone_host     => $controller_node_address,
    murano_keystone_user     => 'murano',
    murano_keystone_password => $murano_hash['user_password'],
    murano_keystone_tenant   => 'services',

    use_neutron              => $use_quantum,
  }
}