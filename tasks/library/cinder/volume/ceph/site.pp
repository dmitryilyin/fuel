class { 'cinder::volume':
  enabled        => true,
  package_ensure => 'present',
}

class {'cinder::volume::ceph': }

Class['cinder::volume'] -> Class['cinder::volume::ceph']
