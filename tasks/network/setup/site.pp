$fuel_settings = parseyaml($astute_settings_yaml)
$use_quantum = $fuel_settings['quantum']

class { 'l23network':
  use_ovs => $use_quantum,
}

if $use_quantum {
  prepare_network_config($fuel_settings['network_scheme'])
  $sdn = generate_network_config()
  notify {"SDN: ${sdn}": }
} else {
  class { 'osnailyfacter::network_setup' :}
  Class['l23network'] -> Class['osnailyfacter::network_setup']
}