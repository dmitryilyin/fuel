$fuel_settings = parseyaml($::astute_settings_yaml)

$api_bind_address = '0.0.0.0'

$verbose = true
$debug = $fuel_settings['debug']

class { 'openstack::horizon':
  bind_address      => $api_bind_address,
  verbose           => $verbose,
  debug             => $debug,
}
