# HA configuration for MySQL/Galera for OpenStack
class openstack::ha::mysqld (
  $before_start = false
){

  openstack::ha::haproxy_service { 'mysqld':
    order               => '110',
    listen_port         => 3306,
    balancermember_port => 3307,
    define_backups      => true,
    before_start        => $before_start,

    haproxy_config_options => {
      'option'         => ['httpchk', 'tcplog','clitcpka','srvtcpka'],
      'balance'        => 'leastconn',
      'mode'           => 'tcp',
      'timeout server' => '28801s',
      'timeout client' => '28801s'
    },

    balancermember_options => 'check port 49000 inter 15s fastinter 2s downinter 1s rise 3 fall 3',
  }

  package { 'socat' :
    ensure => 'installed',
  }

  # wait-for-haproxy-mysql-backend
  haproxy_backend_status { 'mysqld' :
    url => "http://${::fuel_settings['management_vip']}:10000/;csv",
  }

  Class['cluster::haproxy_ocf'] -> Haproxy_backend_status['mysqld']
  Exec<| title == 'wait-for-synced-state' |> -> Haproxy_backend_status['mysqld']
  Openstack::Ha::Haproxy_service<| title == 'mysqld' |> -> Haproxy_backend_status['mysqld']
  Haproxy_backend_status['mysqld'] -> Exec<| title == 'keystone-manage db_sync' |>
  Haproxy_backend_status['mysqld'] -> Exec<| title == 'glance-manage db_sync' |>
  Haproxy_backend_status['mysqld'] -> Exec<| title == 'cinder-manage db_sync' |>
  Haproxy_backend_status['mysqld'] -> Exec<| title == 'nova-db-sync' |>
  Haproxy_backend_status['mysqld'] -> Exec<| title == 'heat-dbsync' |>
  Haproxy_backend_status['mysqld'] -> Exec<| title == 'ceilometer-dbsync' |>
  Haproxy_backend_status['mysqld'] -> Exec<| title == 'neutron-db-sync' |>
  Haproxy_backend_status['mysqld'] -> Service <| title == 'cinder-scheduler' |>
  Haproxy_backend_status['mysqld'] -> Service <| title == 'cinder-volume' |>
  Haproxy_backend_status['mysqld'] -> Service <| title == 'cinder-api' |>

}
