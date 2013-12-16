class murano::api (
  $verbose                    = true,
  $debug                      = true,
  $use_syslog                 = true,
  $syslog_facility            = 'LOG_LOCAL0',
  $paste_inipipeline          = 'authtoken context apiv1app',
  $paste_app_factory          = 'muranoapi.api.v1.router:API.factory',
  $paste_filter_factory       = 'muranoapi.api.middleware.context:ContextMiddleware.factory',
  $paste_paste_filter_factory = 'keystoneclient.middleware.auth_token:filter_factory',
  $paste_auth_host            = '127.0.0.1',
  $paste_auth_port            = '35357',
  $paste_auth_protocol        = 'http',
  $paste_admin_tenant_name    = 'admin',
  $paste_admin_user           = 'admin',
  $paste_admin_password       = 'admin',
  $paste_signing_dir          = '/tmp/keystone-signing-muranoapi',
  $bind_host                  = '0.0.0.0',
  $bind_port                  = '8082',
  $log_file                   = '/var/log/murano/murano-api.log',
  $database_auto_create       = true,
  $reports_results_exchange   = 'task-results',
  $reports_results_queue      = 'task-results',
  $reports_reports_exchange   = 'task-reports',
  $reports_reports_queue      = 'task-reports',
  $rabbit_host                = '127.0.0.1',
  $rabbit_port                = '5672',
  $rabbit_ssl                 = false,
  $rabbit_ca_certs            = '',
  $rabbit_login               = 'murano',
  $rabbit_password            = 'murano',
  $rabbit_virtual_host        = '/',
  $firewall_rule_name         = '202 murano-api',

  $murano_db_password         = 'murano',
  $murano_db_name             = 'murano',
  $murano_db_user             = 'murano',
  $murano_db_host             = '127.0.0.1',
  
  $package_name                = $murano::params::api_package_name,
  $service_name                = $murano::params::api_service_name,
) inherits murano::params {

  $database_connection = "mysql://${murano_db_name}:${murano_db_password}@${murano_db_host}:3306/${murano_db_name}"

  include murano::params

  package { 'murano_api':
    ensure => installed,
    name   => $package_name,
  }

  service { 'murano_api':
    ensure     => 'running',
    name       => $service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  murano_api_config {
    'DEFAULT/verbose'                       : value => $verbose;
    'DEFAULT/debug'                         : value => $debug;
    'DEFAULT/bind_host'                     : value => $bind_host;
    'DEFAULT/bind_port'                     : value => $bind_port;
    'DEFAULT/log_file'                      : value => $log_file;
    'DEFAULT/use_syslog'                    : value => $use_syslog;
    'DEFAULT/syslog-log-facility'           : value => $syslog_facility;
    'database/connection'                   : value => $database_connection;
    'database/auto_create'                  : value => $database_auto_create;
    'reports/results_exchange'              : value => $reports_results_exchange;
    'reports/results_queue'                 : value => $reports_results_queue;
    'reports/reports_exchange'              : value => $reports_reports_exchange;
    'reports/reports_queue'                 : value => $reports_reports_queue;
    'rabbitmq/host'                         : value => $rabbit_host;
    'rabbitmq/port'                         : value => $rabbit_port;
    'rabbitmq/ssl'                          : value => $rabbit_ssl;
    'rabbitmq/ca_certs'                     : value => $rabbit_ca_certs;
    'rabbitmq/login'                        : value => $rabbit_login;
    'rabbitmq/password'                     : value => $rabbit_password;
    'rabbitmq/virtual_host'                 : value => $rabbit_virtual_host;
    'keystone_authtoken/auth_host'          : value => $paste_auth_host;
    'keystone_authtoken/auth_port'          : value => $paste_auth_port;
    'keystone_authtoken/auth_protocol'      : value => $paste_auth_protocol;
    'keystone_authtoken/admin_tenant_name'  : value => $paste_admin_tenant_name;
    'keystone_authtoken/admin_user'         : value => $paste_admin_user;
    'keystone_authtoken/admin_password'     : value => $paste_admin_password;
    'keystone_authtoken/signing_dir'        : value => $paste_signing_dir;
  }

  murano_api_paste_ini_config {
    'pipeline:muranoapi/pipeline'           : value => $paste_inipipeline;
    'app:apiv1app/paste.app_factory'        : value => $paste_app_factory;
    'filter:context/paste.filter_factory'   : value => $paste_filter_factory;
    'filter:authtoken/paste.filter_factory' : value => $paste_paste_filter_factory;
  }

  firewall { $firewall_rule_name :
    dport   => [ $bind_port ],
    proto   => 'tcp',
    action  => 'accept',
  }

  Package['murano_api'] -> Murano_api_config<||> ~> Service['murano_api']
  Package['murano_api'] -> Murano_api_paste_ini_config<||> ~> Service['murano_api']

}
