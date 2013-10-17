class heat::install(
  $password       = 'heat',
  $dbname         = 'heat',
  $user           = 'heat',
  $dbhost         = 'localhost',
  $charset        = 'utf8',
  $allowed_hosts  = undef,
) {

  include heat::params

  # package install hacks

  exec { 'touch_heat_engine_config':
    command     => '/usr/bin/touch /etc/heat/heat-engine.conf',
    path        => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin', '/usr/local/sbin' ],
    user        => 'heat',
    logoutput   => 'on_failure',
  }
  
  $sql_connection = "mysql://${user}:${password}@${dbhost}/${dbname}"
  heat_engine_config_db_sync {
    'DEFAULT/sql_connection': value => $sql_connection;
  }

  file { '/etc/dbconfig-common/':
    ensure => "directory",
  }

  file {'/etc/dbconfig-common/heat-engine.conf':
    ensure  => present,
    content => "dbc_install='false'\ndbc_upgrade='true'\ndbc_remove='false'\ndbc_dbtype='mysql'\ndbc_dbuser='heat'\ndbc_dbpass='heat'\ndbc_dbserver=''\ndbc_dbport=''\ndbc_dbname='heat'\ndbc_dbadmin='root'\ndbc_basepath=''\ndbc_ssl=''\ndbc_authmethod_admin=''\ndbc_authmethod_user=''",
    owner   => 'root',
    group   => 'root',
  }

  # basic users and configs

  group { 'heat' :
    ensure  => present,
    name    => 'heat',
  }

  user { 'heat' :
    ensure  => present,
    name    => 'heat',
    gid     => 'heat',
    groups  => ['heat'],
    system  => true,
  }

  file { '/etc/heat' :
    ensure  => directory,
    owner   => 'heat',
    group   => 'heat',
    mode    => '0750',
  }
  
  # packages
  
  package { 'heat-common' :
    ensure => installed,
    name   => $::heat::params::common_package_name,
  }
  
  package { 'python-pbr' :
    ensure => present,
    name   => $::heat::params::deps_pbr_package_name,
  }
  
  if $::osfamily == 'RedHat' {
    package { 'heat-cli':
      ensure => present,
      name   => $::heat::params::heat_cli_package_name,
    }
    Package['python-pbr'] -> Package['heat-cli'] -> Package['heat-common']
  }
  
  package { 'python-heatclient':
    ensure  => present,
    name    => $::heat::params::client_package_name,
  }
  
  package { 'python-routes':
    ensure => installed,
    name   => $::heat::params::deps_routes_package_name,
  }
  
  class { 'mysql::python' : }
  
  # database
  
  mysql::db { $dbname :
    user         => $user,
    password     => $password,
    host         => $dbhost,
    charset      => $charset,
    grant        => ['all'],
  }
  
  if $allowed_hosts {
    heat::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }

  #install basic packages
  Package['python-heatclient'] -> Package['python-routes'] -> Package['python-pbr'] -> Class['mysql::python'] -> Package['heat-common']

  # basic users and configs
  Package['heat-common'] -> Group['heat'] -> User['heat'] -> File['/etc/heat']

  #configs for package install
  File['/etc/heat'] -> Exec['touch_heat_engine_config'] -> Heat_engine_config_db_sync<||> -> File['/etc/dbconfig-common/'] -> File['/etc/dbconfig-common/heat-engine.conf']

}
