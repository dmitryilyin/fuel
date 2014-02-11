class { 'memcached' :}

#  $memcached_addresses =  inline_template("<%= @cache_server_ip.collect {|ip| ip + ':' + @cache_server_port }.join ',' %>")
#  nova_config {'DEFAULT/memcached_servers':
#    value => $memcached_addresses
#  }
