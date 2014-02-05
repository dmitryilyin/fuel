    class { 'nova::vncproxy':
      host           => $public_address,
      enabled        => $enabled,
      ensure_package => $ensure_package
    }
