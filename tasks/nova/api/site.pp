class { '::nova::api':
  enabled           => $enabled,
  admin_password    => $nova_user_password,
  auth_host         => $keystone_host,
  enabled_apis      => $_enabled_apis,
  ensure_package    => $ensure_package,
  nova_rate_limits  => $nova_rate_limits,
  cinder            => $cinder
}
