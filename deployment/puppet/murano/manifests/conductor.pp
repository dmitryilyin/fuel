# Installs & configure the murano conductor  service

class murano::conductor (
  $debug                               = true,
  $verbose                             = true,
  $use_neutron                         = true,
  $use_syslog                          = true,
  $syslog_facility                     = 'LOG_LOCAL0',
  $log_file                            = '/var/log/murano/conductor.log',
  $data_dir                            = '/tmp/muranoconductor-cache',
  $max_environments                    = '20',
  $auth_url                            = 'http://127.0.0.1:5000/v2.0',
  $rabbit_host                         = '127.0.0.1',
  $rabbit_port                         = '5672',
  $rabbit_ssl                          = false,
  $rabbit_ca_certs                     = '',
  $rabbit_ca                           = '',
  $rabbit_login                        = 'murano',
  $rabbit_password                     = 'murano',
  $rabbit_virtual_host                 = '/',
  $init_scripts_dir                    = '/etc/murano/init-scripts',
  $agent_config_dir                    = '/etc/murano/agent-config',
  $package_name                        = $murano::params::conductor_package_name,
  $service_name                        = $murano::params::conductor_service_name,
) inherits murano::params {

  package { 'murano_conductor':
    ensure => installed,
    name   => $package_name,
  }

  service { 'murano_conductor':
    ensure     => 'running',
    name       => $service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  if $use_neutron {
    $network_topology = 'routed'
  } else {
    $network_topology = 'nova'
  }

  murano_conductor_config {
    'DEFAULT/log_file'                 : value => $log_file;
    'DEFAULT/debug'                    : value => $debug;
    'DEFAULT/verbose'                  : value => $verbose;
    'DEFAULT/use_syslog'               : value => $use_syslog;
    'DEFAULT/syslog-log-facility'      : value => $syslog_facility;
    'DEFAULT/data_dir'                 : value => $data_dir;
    'DEFAULT/max_environments'         : value => $max_environments;
    'DEFAULT/init_scripts_dir'         : value => $init_scripts_dir;
    'DEFAULT/agent_config_dir'         : value => $agent_config_dir;
    'DEFAULT/anetwork_topology'        : value => $network_topology;
    'keystone/auth_url'                : value => $auth_url;
    'rabbitmq/host'                    : value => $rabbit_host;
    'rabbitmq/port'                    : value => $rabbit_port;
    'rabbitmq/ssl'                     : value => $rabbit_ssl;
    'rabbitmq/ca_certs'                : value => $rabbit_ca;
    'rabbitmq/login'                   : value => $rabbit_login;
    'rabbitmq/password'                : value => $rabbit_password;
    'rabbitmq/virtual_host'            : value => $rabbit_virtual_host;
  }

  Package['murano_conductor'] -> Murano_conductor_config<||> ~> Service['murano_conductor']

}
