$fuel_settings = parseyaml($::astute_settings_yaml)

$rabbit_hash   = $fuel_settings['rabbit']
$keystone_hash = $fuel_settings['keystone']
$nodes_hash    = $fuel_settings['nodes']
$nova_hash     = $fuel_settings['nova']

$controller = filter_nodes($nodes_hash,'role','controller')
$controller_node_address = $controller[0]['internal_address']
$controller_node_public  = $controller[0]['public_address']

if !$rabbit_hash['user'] {
  $rabbit_hash['user'] = 'nova'
}

$rabbit_user = $rabbit_hash['user']
$rabbit_password = $rabbit_hash['password']

$db_user     = 'keystone'
$db_password = $keystone_hash['db_password']
$db_name     = 'keystone'
$db_host     = '127.0.0.1'

$nova_db = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"

$glance_connection = "${$controller_node_public}:9292"
$rabbit_connection = $controller_node_address

$nova_user_password = $nova_hash['user_password']

$verbose = true
$debug = $fuel_settings['debug']

$auto_assign_floating_ip = $fuel_settings['auto_assign_floating_ip']

class { 'nova':
  sql_connection     => $nova_db,
  rabbit_userid      => $rabbit_user,
  rabbit_password    => $rabbit_password,
  image_service      => 'nova.image.glance.GlanceImageService',
  glance_api_servers => $glance_connection,
  verbose            => $verbose,
  debug              => $debug,
  rabbit_host        => $rabbit_connection,
  use_syslog         => true,
}

$nova_rate_limits = {
  'POST' => 1000,
  'POST_SERVERS' => 1000,
  'PUT' => 1000, 'GET' => 1000,
  'DELETE' => 1000
}

class { 'nova::quota':
  quota_instances                       => 100,
  quota_cores                           => 100,
  quota_volumes                         => 100,
  quota_gigabytes                       => 1000,
  quota_floating_ips                    => 100,
  quota_metadata_items                  => 1024,
  quota_max_injected_files              => 50,
  quota_max_injected_file_content_bytes => 102400,
  quota_max_injected_file_path_bytes    => 4096
}

class { 'nova::api':
  admin_password    => $nova_user_password,
  nova_rate_limits  => $nova_rate_limits,
  cinder            => false,
}

class { 'nova::conductor' :}

nova_config { 'DEFAULT/auto_assign_floating_ip':
  value => $auto_assign_floating_ip,
}

class { 'nova::scheduler' :}

class { 'nova::objectstore' :}

class { 'nova::cert' :}

class { 'nova::consoleauth' :}

class { 'nova::vncproxy':
  host => $controller_node_public,
}
