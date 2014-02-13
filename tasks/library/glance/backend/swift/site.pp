class { 'glance::backend::swift' :
  swift_store_user => "services:glance",
  swift_store_key=> $glance_user_password,
  swift_store_create_container_on_put => "True",
  swift_store_auth_address => "http://${keystone_host}:5000/v2.0/"
}
