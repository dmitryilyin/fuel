# Allow a user to access the heat database
#
# == Namevar
#  The host to allow
#
# == Parameters
#  [*user*]
#    username to allow
#
#  [*password*]
#    user password
#
#  [*database*]
#    the database name
#
define heat::host_access ($user, $password, $database)  {

  database_user { "${user}@${name}":
    password_hash => mysql_password($password),
    provider      => 'mysql',
    require       => Database[$database],
  }

  database_grant { "${user}@${name}/${database}":
    privileges => 'all',
    provider   => 'mysql',
    require    => Database_user["${user}@${name}"]
  }

}
