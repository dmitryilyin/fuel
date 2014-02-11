# Proxy realization via apache
class osnailyfacter::apache_api_proxy (
  $source_ip = '127.0.0.1',
) {

  # Allow connection to the apache for ostf tests
  firewall {'007 tinyproxy' :
    dport   => [ 8888 ],
    source  => $source_ip,
    proto   => 'tcp',
    action  => 'accept',
  }

  if defined(Class['openstack::firewall']) {
    Class['openstack::firewall'] -> Firewall['007 tinyproxy']
  }

  if ($::osfamily == 'Debian') {

    file { 'api_proxy.conf' :
      path    => '/etc/apache2/sites-available/api_proxy.conf',
      content => template('osnailyfacter/api_proxy.conf.erb'),
    }

    file { 'api_proxy.link' :
      path   => '/etc/apache2/sites-enabled/api_proxy.conf',
      ensure => 'link',
      target => '/etc/apache2/sites-available/api_proxy.conf',
    }

    $required_modules = ['proxy', 'proxy_http']
    a2mod { $required_modules : }

    Package <| title == 'httpd' |> -> a2mod { $required_modules : } ~> Service <| title == 'httpd' |>
    File['api_proxy.conf', 'api_proxy.link'] ~> Service <| title == 'httpd' |>    

  } elsif ($::osfamily == 'RedHat') {

    file { 'api_proxy.conf' :
      path    => '/etc/httpd/conf.d/api_proxy.conf',
      content => template('osnailyfacter/api_proxy.conf.erb'),
    }
    
    Package <| title == 'httpd' |> -> File['api_proxy.conf'] ~> Service <| title == 'httpd' |>

  } else {
    fail("Module does not support ${::ofamily}")
  }

}
