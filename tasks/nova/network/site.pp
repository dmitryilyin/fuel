$fuel_settings = parseyaml($::astute_settings_yaml)

$nodes_hash = $fuel_settings['nodes']
$nova_hash  = $fuel_settings['nova']

$controller  = filter_nodes($nodes_hash,'role','controller')
$controller_node_address = $controller[0]['internal_address']
$controller_node_public  = $controller[0]['public_address']

$fixed_range = $fuel_settings['fixed_network_range']
$nameservers = $fuel_settings['dns_nameservers']

$floating_range = false
$create_networks = true
$enable_network_service = true
$config_overrides = {}

$novanetwork_params   = $fuel_settings['novanetwork_parameters']
$num_networks         = $novanetwork_params['num_networks']
$network_size         = $novanetwork_params['network_size']
$network_manager      = "nova.network.manager.${novanetwork_params['network_manager']}"

class { 'nova::network' :
  private_interface => $controller_node_address,
  public_interface  => $controller_node_public,
  fixed_range       => $fixed_range,
  floating_range    => $floating_range,
  network_manager   => $network_manager,
  config_overrides  => $config_overrides,
  create_networks   => $create_networks,
  num_networks      => $num_networks,
  network_size      => $network_size,
  nameservers       => $nameservers,
  enabled           => $enable_network_service,
  install_service   => $enable_network_service,
}
