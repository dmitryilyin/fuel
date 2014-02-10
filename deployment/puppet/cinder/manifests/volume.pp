# $volume_name_template = volume-%s
class cinder::volume (
  $package_ensure = 'latest',
  $enabled        = true
) {

  include cinder::params

  if ($::cinder::params::volume_package) { 
    $volume_package = $::cinder::params::volume_package
    if defined(Package['cinder']) {
      Package['cinder'] -> Package[$volume_package]
    }

    package { 'cinder-volume':
      name   => $volume_package,
      ensure => $package_ensure,
    }
  } else {
    $volume_package = $::cinder::params::package_name
  }
  
  case $::osfamily {
    "Debian":  {
      File <| title == $::cinder::params::cinder_conf |> -> Cinder_config<||> ~> Service['cinder-volume']
      File <| title == $::cinder::params::cinder_paste_api_ini |> -> Cinder_api_paste_ini<||>
      Cinder_config <| |> -> Package['cinder-volume']
      Cinder_api_paste_ini<||> -> Package['cinder-volume']
    }
    "RedHat": {
      if defined(Package[$volume_package]) {
        Package[$volume_package] -> Cinder_api_paste_ini<||>
        Package[$volume_package] -> Cinder_config<||>
      }
    }
  }
  
  if defined(Exec['cinder-manage db_sync']) {
    Cinder_config<||> ~> Exec['cinder-manage db_sync']
    Exec['cinder-manage db_sync'] -> Service['cinder-volume']
  }
  
  Cinder_api_paste_ini<||> ~> Service['cinder-volume']

  if $enabled {
    $ensure = 'running'
  } else {
    $ensure = 'stopped'
  }

  service { 'cinder-volume':
    name      => $::cinder::params::volume_service,
    enable    => $enabled,
    ensure    => $ensure,
  }
  
  Package <| title == $volume_package |> -> Service['cinder-volume']

}
