file { '/tmp/test' :
  ensure  => present,
  content => 'test file',
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
}
