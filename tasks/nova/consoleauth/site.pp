  class { '::nova::consoleauth':
    enabled        => $enabled,
    ensure_package => $ensure_package,
  }
