case $::osfamily {
  'RedHat': {
    $web_root   = '/var/www/html'
    $index_file = 'index.html'
  }
  'Debian': {
    $web_root   = '/var/www'
    $index_file = 'index.html'
  }
  default: {
    fail("unsupported osfamily: ${::osfamily}")
  }
}

$html = "<!doctype html>\n<html lang='en'>\n<head>\n<meta charset='utf-8' />\n<title>Demo Page</title>\n<style media='screen' type='text/css'>\nh1 {\n  color: red;\n  font-size: 3em;\n}\n#text {\n  color: blue;\n  font-size: 2em;\n}\n</style>\n</head>\n<body>\n<h1>Granular Deployment Demo Page</h1>\n<div id='text'>\nHello World!\n</div>\n</body>\n</html>\n"
$file = "${web_root}/${index_file}"

File {
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
}

file { 'index_file' :
  ensure  => present,
  path    => $file,
  content => $html,
}

file { 'web_root' :
  path   => $web_root,
  ensure => directory,
}
