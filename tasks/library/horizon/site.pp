$fuel_settings = parseyaml($::astute_settings_yaml)

$bind_address = '0.0.0.0'
$secret_key = 'dummy_secret_key'

class { 'horizon' :
  secret_key   => $secret_key,
  bind_address => $bind_address,
}

