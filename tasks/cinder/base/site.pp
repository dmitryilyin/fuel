$fuel_settings = parseyaml($::astute_settings_yaml)
$rabbit_hash   = $fuel_settings['rabbit']
$nodes_hash    = $fuel_settings['nodes']
$cinder_hash   = $fuel_settings['cinder']

$rabbit_password = $rabbit_hash['password']
$qpid_password   = $rabbit_hash['password']

$controller = filter_nodes($nodes_hash,'role','controller')
$controller_node_address = $controller[0]['internal_address']
$controller_node_public  = $controller[0]['public_address']

$rabbit_hosts = "${$controller_node_address}:5672"

$db_password = $cinder_hash['db_password']
$db_user     = 'cinder'
$db_dbname   = 'cinder'
$db_host     = $controller_node_address

$sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_dbname}?charset=utf8"

$verbose = true
$debug = true
$use_syslog = true

class { 'cinder::base':
  package_ensure  => 'present',
  rabbit_password => $rabbit_password,
  qpid_password   => $qpid_password,
  rabbit_hosts    => $rabbit_hosts,
  sql_connection  => $sql_connection,
  verbose         => $verbose,
  use_syslog      => $use_syslog,
  debug           => $debug,
}
