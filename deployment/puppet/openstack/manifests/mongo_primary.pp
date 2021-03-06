# == Class: openstack::mongo_primary

class openstack::mongo_primary (
  $ceilometer_database          = "ceilometer",
  $ceilometer_user              = "ceilometer",
  $ceilometer_metering_secret   = undef,
  $ceilometer_db_password       = "ceilometer",
  $ceilometer_metering_secret   = "ceilometer",
  $ceilometer_replset_members   = ['mongo2', 'mongo3'],
  $mongodb_bind_address         = ['0.0.0.0'],
  $mongodb_port                 = 27017,
) {

  if size($ceilometer_replset_members) > 0 {
    $replset_setup = true
    $keyfile = '/etc/mongodb.key'
    $replset = 'ceilometer'
  } else {
    $replset_setup = false
    $keyfile = undef
    $replset = undef
  }

  notify {"MongoDB params: $mongodb_bind_address" :} ->

  class {'::mongodb::client':
  } ->

  class {'::mongodb::server':
    port    => $mongodb_port,
    verbose => true,
    bind_ip => $mongodb_bind_address,
    auth    => true,
    replset => $replset,
    keyfile => $keyfile,
  } ->

  class {'::mongodb::replset':
    replset_setup   => $replset_setup,
    replset_members => $ceilometer_replset_members,
  } ->

  notify {"mongodb configuring databases" :} ->

  mongodb::db { $ceilometer_database:
    user          => $ceilometer_user,
    password      => $ceilometer_db_password,
    roles         => [
      'readWrite',
      'dbAdmin',
      'dbOwner'
    ],
  } ->

  mongodb::db { 'admin':
    user         => 'admin',
    password     => $ceilometer_db_password,
    roles        => [
      'userAdmin',
      'readWrite',
      'dbAdmin',
      'dbAdminAnyDatabase',
      'readAnyDatabase',
      'readWriteAnyDatabase',
      'userAdminAnyDatabase',
      'clusterAdmin',
      'clusterManager',
      'clusterMonitor',
      'hostManager',
      'root'
    ],
  } ->

  notify {"mongodb primary finished": }

}
# vim: set ts=2 sw=2 et :