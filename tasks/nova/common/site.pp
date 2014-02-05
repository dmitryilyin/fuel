$fuel_settings = parseyaml($::astute_settings_yaml)

$rabbit_hash   = $fuel_settings['rabbit']
$keystone_hash = $fuel_settings['keystone']
$nodes_hash    = $fuel_settings['nodes']
$nova_hash     = $fuel_settings['nova']

$controller = filter_nodes($nodes_hash,'role','controller')
$controller_node_address = $controller[0]['internal_address']
$controller_node_public  = $controller[0]['public_address']

$rabbit_userid   = 'nova'
$rabbit_password = $rabbit_hash['password']

$db_userid   = 'keystone'
$db_password = $keystone_hash['db_password']
$db_name     = 'keystone'
$db_host     = '127.0.0.1'

$nova_db = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"

$glance_connection = "${$controller_node_public}:9292"
$rabbit_connection = $controller_node_address

$verbose = true
$debug = $fuel_settings['debug']

class { 'nova':
  sql_connection     => $nova_db,
  rabbit_userid      => $rabbit_userid,
  rabbit_password    => $rabbit_password,
  image_service      => 'nova.image.glance.GlanceImageService',
  glance_api_servers => $glance_connection,
  verbose            => $verbose,
  debug              => $debug,
  rabbit_host        => $rabbit_connection,
  use_syslog         => false,
}

$auto_assign_floating_ip = $fuel_settings['auto_assign_floating_ip']

nova_config { 'DEFAULT/auto_assign_floating_ip':
  value => $auto_assign_floating_ip,
}
