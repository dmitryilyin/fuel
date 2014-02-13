file { '/tmp/test' :
  ensure  => present,
  content => 'test file',
}
