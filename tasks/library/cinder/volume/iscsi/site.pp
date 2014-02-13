
class { 'cinder::volume':
  enabled        => true,
  package_ensure => 'present',
}

$iscsi_bind_host = '0.0.0.0'

class { 'cinder::volume::iscsi':
  iscsi_ip_address => $iscsi_bind_host,
}

Class['cinder::volume'] -> Class['cinder::volume::iscsi']
        
