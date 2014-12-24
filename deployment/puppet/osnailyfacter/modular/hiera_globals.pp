import 'globals.pp'

$globals_yaml = '/etc/hiera/globals.yaml'

$data = '
---

'

file { 'global_yaml_data' :
  path    => $globals_yaml,
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  content => inline_template($data),
}
