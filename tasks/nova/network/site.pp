class { 'nova::network':
  private_interface => $private_interface,
  public_interface  => $public_interface,
  fixed_range       => $fixed_range,
  floating_range    => $floating_range,
  network_manager   => $network_manager,
  config_overrides  => $network_config,
  create_networks   => $really_create_networks,
  num_networks      => $num_networks,
  network_size      => $network_size,
  nameservers       => $nameservers,
  enabled           => $enable_network_service,
  install_service   => $enable_network_service,
  ensure_package    => $ensure_package
}
