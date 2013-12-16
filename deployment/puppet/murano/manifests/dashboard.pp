class murano::dashboard (
  $local_settings_path = $murano::params::local_settings_path,
  $api_url             = $murano::params::api_url,
  $metadata_url        = $murano::params::metadata_url,
  $dashboard_deps      = $murano::params::dashboard_deps_name,
  $package_name        = $murano::params::dashboard_package_name,
) inherits murano::params {

  file_line { 'api_url' :
    ensure  => present,
    path    => $local_settings_path,
    line    => $api_url,
  }
  
  file_line { 'metadata_url' :
    ensure  => present,
    path    => $local_settings_path,
    line    => $metadata_url,
  }

  package { 'murano_dashboard' :
    ensure => present,
    name   => $package_name,
  }

  package { $dashboard_deps :
    ensure => installed,
  }

  Package[$dashboard_deps] -> Package['murano_dashboard'] ~> Service <| title == 'httpd' |>
  File <| title == $local_settings_path |> -> File_line['api_url'] -> File_line['metadata_url'] 

}
