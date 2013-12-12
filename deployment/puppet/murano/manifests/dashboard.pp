class murano::dashboard (
  $settings_py                    = '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
  $murano_url_string              = $::murano::params::default_url_string,
  $local_settings                 = $::murano::params::local_settings_path,
) {

  include murano::params

  $dashboard_deps = $::murano::params::murano_dashboard_deps
  $package_name   = $::murano::params::murano_dashboard_package_name

  file_line { 'murano_url' :
    ensure  => 'present',
    path    => $local_settings,
    line    => $murano_url_string,
    require => File[$local_settings],
  }

  package { 'murano_dashboard' :
    ensure => present,
    name   => $package_name,
  }

  package { $dashboard_deps :
    ensure => installed,
  }

  Package[$dashboard_deps] -> Package['murano_dashboard'] ~> Service <| title == 'httpd' |>

}
