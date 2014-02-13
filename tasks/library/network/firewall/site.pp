$fuel_settings = parseyaml($::astute_settings_yaml)

class { 'openstack::firewall':
  nova_vnc_ip_range => $::fuel_settings['management_network_range'],
}

firewall {'003 remote rabbitmq ':
  sport   => [ 4369, 5672, 41055, 55672, 61613 ],
  source  => $::fuel_settings['master_ip'],
  proto   => 'tcp',
  action  => 'accept',
  require => Class['openstack::firewall'],
}
