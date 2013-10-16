class heat::preinstall(
  $sql_connection = 'mysql://heat:heat@localhost/heat',
) {
  include heat::params
  
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

}