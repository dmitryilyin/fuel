class murano::db::mysql(
  $password      = 'murano',
  $dbname        = 'murano',
  $user          = 'murano',
  $dbhost        = 'localhost',
  $charset       = 'utf8',
  $allowed_hosts = undef,
) inherits murano::params {

  include 'stdlib'

  anchor { 'murano-db-start' :}
  anchor { 'murano-db-end' :}

  mysql::db { $dbname :
    user     => $user,
    password => $password,
    host     => $dbhost,
    charset  => $charset,
    grant    => ['all'],
  }
  
  if $allowed_hosts {
    murano::db::mysql::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
    Anchor['murano-db-start'] -> Mysql::Db[$dbname] -> Murano::Db::Mysql::Host_access[$allowed_hosts] -> Anchor['murano-db-end']
  } else {
    Anchor['murano-db-start'] -> Mysql::Db[$dbname] -> Anchor['murano-db-end']
  }

}
