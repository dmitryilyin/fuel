class { "::openstack::logging":
  stage          => 'first',
  role           => 'client',
  show_timezone => true,
  # log both locally include auth, and remote
  log_remote     => true,
  log_local      => true,
  log_auth_local => true,
  # keep four weekly log rotations, force rotate if 300M size have exceeded
  rotation       => 'weekly',
  keep           => '4',
  # should be > 30M
  limitsize      => '300M',
  # remote servers to send logs to
  rservers       => $rservers,
  # should be true, if client is running at virtual node
  virtual        => str2bool($::is_virtual),
  # facilities
  syslog_log_facility_glance   => $syslog_log_facility_glance,
  syslog_log_facility_cinder   => $syslog_log_facility_cinder,
  syslog_log_facility_neutron  => $syslog_log_facility_neutron,
  syslog_log_facility_nova     => $syslog_log_facility_nova,
  syslog_log_facility_keystone => $syslog_log_facility_keystone,
  # Rabbit doesn't support syslog directly, should be >= syslog_log_level,
  # otherwise none rabbit's messages would have gone to syslog
  rabbit_log_level => $syslog_log_level,
  # debug mode
  debug          => $debug ? { 'true' => true, true => true, default=> false },
}