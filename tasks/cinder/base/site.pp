  case $queue_provider {
    "rabbitmq": {
      if $rabbit_nodes and !$rabbit_ha_virtual_ip {
        $rabbit_hosts = inline_template("<%= @rabbit_nodes.map {|x| x + ':5672'}.join ',' %>")
        Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-api'|>
        Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-volume' |>
        Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-scheduler' |>
        cinder_config { 'DEFAULT/rabbit_ha_queues': value => 'True' }
      }
      elsif $rabbit_ha_virtual_ip {
        $rabbit_hosts = "${rabbit_ha_virtual_ip}:5672"
        Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-api'|>
        Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-volume' |>
        Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-scheduler' |>
        cinder_config { 'DEFAULT/rabbit_ha_queues': value => 'True' }
      }
    }
    'qpid': {
      $qpid_hosts = inline_template("<%= @qpid_nodes.map {|x| x + ':5672'}.join ',' %>")
    }
  }

  class { 'cinder::base':
    package_ensure  => $::openstack_version['cinder'],
    queue_provider  => $queue_provider,
    rabbit_password => $rabbit_password,
    rabbit_hosts    => $rabbit_hosts,
    qpid_password   => $qpid_password,
    qpid_userid     => $qpid_user,
    qpid_hosts      => $qpid_hosts,
    sql_connection  => $sql_connection,
    verbose         => $verbose,
    use_syslog      => $use_syslog,
    syslog_log_facility => $syslog_log_facility,
    syslog_log_level    => $syslog_log_level,
    debug           => $debug,
  }
