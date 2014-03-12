case $::osfamily {
'RedHat': {
  $package_name = 'httpd'
  $service_name = 'httpd'
}
'Debian': {
  $package_name = ['apache2', 'apache2-mpm-worker', 'apache2-utils', 'apache2.2-bin']
  $service_name = 'apache2'
}
  default: {
    fail("unsupported osfamily: ${::osfamily}")
  }
}

package { 'apache' :
  name   => $package_name,
  ensure => 'purged',
}

service { 'apache' :
  name    => $service_name,
  ensure  => 'stopped',
  enable  => false,
}

Service['apache'] -> Package['apache']