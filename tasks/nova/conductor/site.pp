  class {'::nova::conductor':
    enabled => $enabled,
    ensure_package => $ensure_package,
  }
