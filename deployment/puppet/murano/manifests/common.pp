class murano::common {

  include murano::params

  package { 'murano_common':
    ensure => installed,
    name   => $murano::params::common_package_name,
  }
  
  package { 'murano_metadataclient':
    ensure => installed,
    name   => $murano::params::metadataclient_package_name,
  }
  
  package { 'murano_muranoclient':
    ensure => installed,
    name   => $murano::params::muranoclient_package_name,
  }

}
