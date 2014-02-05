# Provides access to MySQL database
# for given user and host.
#
# mysql::access { '192.168.0.2' :
#   user     => 'my_user',
#   password => 'my_password',
#   database => 'my_database',
#   grant    => 'all',
# }
#
define mysql::access (
  $user,
  $password,
  $database,
  $grant    = 'all',
) {
  
  $host = $name

  database_user { "${user}@${host}":
    provider      => 'mysql',
    password_hash => mysql_password($password),
  }

  database_grant { "${user}@${host}/${database}" :
    provider   => 'mysql',
    privileges => $grant,
  }
  
  Database <| title == $database |> -> Database_user["${user}@${host}"] -> Database_grant["${user}@${host}/${database}"]

  if defined(Class['mysql::server']) {
    Class['mysql::server'] -> Database <| title == $database |>
  }

}
