# Creates MySQL database, user and access for the given host
#
# mysql::account { $my_database :
#  user     => $my_user,
#  password => $my_password,
#  host     => '192.168.0.1',
#  allowed  => ['192.168.0.2', '192.168.0.3'],
#  grant    => 'all',
# }
#
define mysql::account (
  $user,
  $password,
  $charset  = 'utf8',
  $host     = 'localhost',
  $grant    = 'all',
  $allowed  = undef,
) {
  require 'stdlib'

  $database = $name
  
  anchor { "begin_account_${database}" :}
  anchor { "end_account_${database}" :}

  database { $database:
    ensure   => present,
    charset  => $charset,
    provider => 'mysql',
  }

  database_user { "${user}@${host}" :
    ensure        => present,
    password_hash => mysql_password($password),
    provider      => 'mysql',
  }

  database_grant { "${user}@${host}/${database}" :
    privileges => $grant,
    provider   => 'mysql',
  }

  Anchor["begin_account_${database}"] ->
  Database[$database] ->
  Database_user["${user}@${host}"] ->
  Database_grant["${user}@${host}/${database}"] ->
  Anchor["end_account_${database}"]

  if defined(Class['mysql::server']) {
    Class['mysql::server'] -> Anchor["begin_account_${database}"]
  }

  if $allowed {
    mysql::access { $allowed :
      user     => $user,
      password => $password,
      database => $database, 
    }
    
    Database[$database] -> Mysql::Access[$allowed] -> Anchor["end_account_${database}"]

  }

}
