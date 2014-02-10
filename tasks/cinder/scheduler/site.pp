class { 'cinder::scheduler':
  package_ensure => 'present',
  enabled        => true,
}
