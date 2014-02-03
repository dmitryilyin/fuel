$fuel_settings = parseyaml($astute_settings_yaml)

class { 'l23network':
  use_ovs => true,
}

prepare_network_config($fuel_settings['network_scheme'])

$sdn = generate_network_config()

notify { "SDN: ${sdn}": }