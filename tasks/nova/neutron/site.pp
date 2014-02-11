#    class { '::neutron::server':
#      neutron_config     => $quantum_config,
#      primary_controller => $primary_controller
#    }
#    if $quantum and !$quantum_network_node {
#      class { '::neutron':
#        neutron_config       => $quantum_config,
#        verbose              => $verbose,
#        debug                => $debug,
#        use_syslog           => $use_syslog,
#        syslog_log_facility  => $syslog_log_facility_neutron,
#        syslog_log_level     => $syslog_log_level,
#        server_ha_mode       => $ha_mode,
#      }
#    }
#    #todo: <<<
#    class { '::nova::network::neutron':
#      neutron_config => $quantum_config,
#      neutron_connection_host => $service_endpoint
#    }
