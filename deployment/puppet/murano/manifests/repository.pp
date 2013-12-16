class murano::repository (
    $verbose             = true,
    $debug               = true,
    $bind_host           = '0.0.0.0',
    $bind_port           = '8084',
    $manifests           = 'Services',
    $ui                  = 'ui_forms',
    $workflows           = 'workflows',
    $heat                = 'heat_templates',
    $agent               = 'agent_templates',
    $scripts             = 'scripts',
    $output_ui           = 'service_forms',
    $output_workflows    = 'workflows',
    $output_heat         = 'templates/cf',
    $output_agent        = 'templates/agent',
    $output_scripts      = 'templates/agent/scripts',
    $auth_host           = '127.0.0.1',
    $auth_port           = '5000',
    $auth_protocol       = 'http',
    $admin_user          = 'admin',
    $admin_password      = 'swordfish',
    $admin_tenant_name   = 'admin',
    $firewall_rule_name  = '207 murano-repository',
    $service_name        = $murano::params::repository_service_name,
    $package_name        = $murano::params::repository_package_name,
) inherits murano::params {

  package { 'murano_repository':
    ensure => installed,
    name   => $package_name,
  }

  service { 'murano_repository':
    ensure     => 'running',
    name       => $service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  firewall { $firewall_rule_name :
    dport   => [ $bind_port ],
    proto   => 'tcp',
    action  => 'accept',
  }

  murano_repository_config {
    'DEFAULT/host'                : value => $bind_host;
    'DEFAULT/port'                : value => $bind_port;
    'DEFAULT/manifests'           : value => $manifests;
    'DEFAULT/ui'                  : value => $ui;
    'DEFAULT/workflows'           : value => $workflows;
    'DEFAULT/heat'                : value => $heat;
    'DEFAULT/agent'               : value => $agent;
    'DEFAULT/scripts'             : value => $scripts;
    'output/ui'                   : value => $ui;
    'output/workflows'            : value => $output_workflows;
    'output/heat'                 : value => $output_heat;
    'output/agent'                : value => $output_agent;
    'output/scripts'              : value => $output_scripts;
    'keystone/auth_host'          : value => $auth_host;
    'keystone/auth_port'          : value => $auth_port;
    'keystone/auth_protocol'      : value => $auth_protocol;
    'keystone/admin_user'         : value => $admin_user;
    'keystone/admin_password'     : value => $admin_password;
    'keystone/admin_tenant_name'  : value => $admin_tenant_name
  }

  Package['murano_repository'] -> Murano_repository_config<||> ~> Service['murano_repository']

}
