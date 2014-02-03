$fuel_settings = parseyaml($astute_settings_yaml)

class { 'l23network':
  use_ovs => false,
}

class { 'osnailyfacter::network_setup': }