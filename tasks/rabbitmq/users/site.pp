$fuel_settings = parseyaml($::astute_settings_yaml)
$rabbit_hash = $fuel_settings['rabbit']

if !$rabbit_hash['user'] {
  $rabbit_hash['user'] = 'nova'
}

$rabbit_user = $rabbit_hash['user']
$rabbit_password = $rabbit_hash['password']
$virtual_host = '/'

rabbitmq_vhost { $virtual_host :
  provider => 'rabbitmqctl',
}

rabbitmq_user { $rabbit_user :
  admin     => true,
  password  => $rabbit_password,
  provider => 'rabbitmqctl',
}

rabbitmq_user_permissions { "${rabbit_user}@${virtual_host}" :
  configure_permission => '.*',
  write_permission     => '.*',
  read_permission      => '.*',
  provider             => 'rabbitmqctl',
}

Rabbitmq_vhost[$virtual_host] -> Rabbitmq_user[$rabbit_user] -> Rabbitmq_user_permissions["${rabbit_user}@${virtual_host}"]
