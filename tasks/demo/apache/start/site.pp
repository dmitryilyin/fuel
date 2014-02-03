case $::osfamily {
  'RedHat': {
    $package_name = 'httpd'
    $service_name = 'httpd'
  }
  'Debian': {
    $package_name = 'apache2'
    $service_name = 'apache2'
  }
  default: {
    fail("unsupported osfamily: ${::osfamily}")
  }
}

package { 'apache' :
  name   => $package_name,
  ensure => 'installed',
}

service { 'apache' :
  name       => $service_name,
  ensure     => 'running',
  enable     => true,
  hasrestart => true,
  hasstatus  => true,
}

Package['apache'] ~> Service['apache']