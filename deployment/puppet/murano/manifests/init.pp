class murano (
  # murano
  $debug                         = true,
  $verbose                       = true,
  $data_dir                      = '/etc/murano',
  $max_environments              = '20',
  $use_neutron                   = true,
  $use_syslog                    = true,
  $syslog_facility               = 'LOG_LOCAL0',
  
  # keystone
  $keystone_host                 = '127.0.0.1',
  $keystone_port                 = '5000',
  $keystone_protocol             = 'http',
  $keystone_tenant               = 'admin',
  $keystone_user                 = 'admin',
  $keystone_password             = 'admin',

  # rabbit
  $rabbit_host                   = '127.0.0.1',
  $rabbit_port                   = '55572',
  $rabbit_ssl                    = false,
  $rabbit_ca_certs               = '',
  $rabbit_login                  = 'murano',
  $rabbit_password               = 'murano',
  $rabbit_virtual_host           = '/',

  # api
  $api_host                      = '127.0.0.1',
  $api_bind_host                 = '0.0.0.0',
  $api_bind_port                 = '8082',
  $api_log_file                  = '/var/log/murano/murano-api.log',
  $api_database_auto_create      = true,
  $api_reports_results_exchange  = 'task-results',
  $api_reports_results_queue     = 'task-results',
  $api_reports_reports_exchange  = 'task-reports',
  $api_reports_reports_queue     = 'task-reports',
  $api_paste_inipipeline          = 'authtoken context apiv1app',
  $api_paste_app_factory          = 'muranoapi.api.v1.router:API.factory',
  $api_paste_filter_factory       = 'muranoapi.api.middleware.context:ContextMiddleware.factory',
  $api_paste_paste_filter_factory = 'keystoneclient.middleware.auth_token:filter_factory',
  $api_paste_signing_dir          = '/tmp/keystone-signing-muranoapi',

  # mysql
  $db_password                   = 'murano',
  $db_name                       = 'murano',
  $db_user                       = 'murano',
  $db_host                       = 'localhost',
  $db_allowed_hosts              = ['localhost','%'],

  # metadata
  $metadata_host                 = '127.0.0.1',
  $metadata_bind_host            = '0.0.0.0',
  $metadata_bind_port            = '8084',
) {

  $keystone_auth_url = "${keystone_protocol}://${keystone_host}:${keystone_port}/v2.0"

  class { 'murano::db::mysql':
    password                             => $db_password,
    dbname                               => $db_name,
    user                                 => $db_user,
    dbhost                               => $db_host,
    allowed_hosts                        => $db_allowed_hosts,
  }

  class { 'murano::common':
  }

  class { 'murano::repository':
    verbose             => $debug,
    debug               => $verbose,
    bind_host           => $metadata_bind_host,
    bind_port           => $metadata_bind_port,
    auth_host           => $keystone_host,
    auth_port           => $keystone_port,
    auth_protocol       => $keystone_protocol,
    admin_user          => $keystone_user,
    admin_password      => $keystone_password,
    admin_tenant_name   => $keystone_tenant,
  }

  class { 'murano::conductor' :
    debug                                => $debug,
    verbose                              => $verbose,
    use_syslog                           => $use_syslog,
    syslog_facility                      => $syslog_facility,
    data_dir                             => $data_dir,
    max_environments                     => $max_environments,
    auth_url                             => $keystone_auth_url,
    rabbit_host                          => $rabbit_host,
    rabbit_port                          => $rabbit_port,
    rabbit_ssl                           => $rabbit_ssl,
    rabbit_ca_certs                      => $rabbit_ca_certs,
    rabbit_login                         => $rabbit_login,
    rabbit_password                      => $rabbit_password,
    rabbit_virtual_host                  => $rabbit_virtual_host,
    use_neutron                          => $use_neutron,
  }

  class { 'murano::api' :
    debug                            => $debug,
    verbose                          => $verbose,
    use_syslog                       => $use_syslog,
    syslog_facility                  => $syslog_facility,
    paste_inipipeline                => $api_paste_inipipeline,
    paste_app_factory                => $api_paste_app_factory,
    paste_filter_factory             => $api_paste_filter_factory,
    paste_paste_filter_factory       => $api_paste_paste_filter_factory,
    paste_auth_host                  => $keystone_host,
    paste_auth_port                  => $keystone_port,
    paste_auth_protocol              => $keystone_protocol,
    paste_admin_tenant_name          => $keystone_tenant,
    paste_admin_user                 => $keystone_user,
    paste_admin_password             => $keystone_password,
    paste_signing_dir                => $api_paste_signing_dir,
    bind_host                        => $api_bind_host,
    bind_port                        => $api_bind_port,
    log_file                         => $api_log_file,
    database_auto_create             => $api_database_auto_create,
    reports_results_exchange         => $api_reports_results_exchange,
    reports_results_queue            => $api_reports_results_queue,
    reports_reports_exchange         => $api_reports_reports_exchange,
    reports_reports_queue            => $api_reports_reports_queue,

    rabbit_host                      => $rabbit_host,
    rabbit_port                      => $rabbit_port,
    rabbit_ssl                       => $rabbit_ssl,
    rabbit_ca_certs                  => $rabbit_ca_certs,
    rabbit_login                     => $rabbit_login,
    rabbit_password                  => $rabbit_password,
    rabbit_virtual_host              => $rabbit_virtual_host,

    murano_db_password               => $db_password,
    murano_db_name                   => $db_name,
    murano_db_user                   => $db_user,
    murano_db_host                   => $db_host,
  }

  class { 'murano::dashboard' :
    api_url      => "MURANO_API_URL = 'http://${api_host}:${api_bind_port}'",
    metadata_url => "MURANO_API_URL = 'http://${metadata_host}:${metadata_bind_port}'",
  }

  class { 'murano::rabbitmq' :
    rabbit_user        => $rabbit_login,
    rabbit_password    => $rabbit_password,
    rabbit_vhost       => $rabbit_virtual_host,
    rabbitmq_main_port => $rabbit_port,
  }

  anchor { 'murano-start' :}
  anchor { 'murano-end' :}

  # ordering
  Class['mysql::server'] ->
  Anchor['murano-start'] ->
  Class['murano::common'] ->
  Class['murano::db::mysql'] ->
  Class['murano::rabbitmq'] ->
  Class['murano::conductor'] ->
  Class['murano::api'] ->
  Class['murano::repository'] ->
  Class['murano::dashboard'] ->
  Anchor['murano-end']

}
