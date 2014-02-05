      class { 'ceilometer::db::mysql':
        user          => $ceilometer_db_user,
        password      => $ceilometer_db_password,
        dbname        => $ceilometer_db_dbname,
        allowed_hosts => $allowed_hosts,
      }
