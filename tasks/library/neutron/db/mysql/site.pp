      class { 'neutron::db::mysql':
        user          => $neutron_db_user,
        password      => $neutron_db_password,
        dbname        => $neutron_db_dbname,
        allowed_hosts => $allowed_hosts,
      }
