      class { 'cinder::db::mysql':
        user          => $cinder_db_user,
        password      => $cinder_db_password,
        dbname        => $cinder_db_dbname,
        allowed_hosts => $allowed_hosts,
      }
