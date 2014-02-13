Configure Apache vhost as proxy server.

It will be used by OSTF tests on master node because
there is no direct access to nova-api on the public
IP of the controller node.

This proxy servers transfers requests from internal
IP address to the public one.
