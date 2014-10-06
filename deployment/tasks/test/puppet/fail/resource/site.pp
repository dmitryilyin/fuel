notify { 'Puppet Apply Fail' :}
->
exec { '/bin/false' :}