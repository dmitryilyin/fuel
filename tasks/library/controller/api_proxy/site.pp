$fuel_settings = parseyaml($::astute_settings_yaml)

class { 'osnailyfacter::apache_api_proxy': 
  source_ip => $fuel_settings['master_ip']
}

include 'horizon::params'

service { 'httpd':
  name      => $horizon::params::http_service,
  ensure    => 'running',
  enable    => true
}

