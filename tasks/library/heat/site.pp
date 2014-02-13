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

if ($::operatingsystem != 'RedHat') {
  class { 'heat' :
    pacemaker              => false,
    external_ip            => $controller_node_public,

    heat_keystone_host     => $controller_node_address,
    heat_keystone_user     => 'heat',
    heat_keystone_password => 'heat',
    heat_keystone_tenant   => 'services',

    heat_rabbit_host       => $controller_node_address,
    heat_rabbit_login      => $rabbit_hash['user'],
    heat_rabbit_password   => $rabbit_hash['password'],
    heat_rabbit_port       => '5672',

    heat_db_host           => $controller_node_address,
    heat_db_password       => $heat_hash['db_password'],
  }
}