from unittest import TestCase


def get_config(hostname, domain, management_interface, management_ip,
               management_mask, external_interface, external_ip, external_mask,
               dhcp_start_address, dhcp_end_address, mirror_type):
    return _get_config(hostname=hostname,
                       domain=domain, mgmt_if=management_interface,
                       mgmt_ip=management_ip, mgmt_mask=management_mask,
                       ext_if=external_interface,
                       ext_ip=external_ip, ext_mask=external_mask,
                       dhcp_start_address=dhcp_start_address,
                       dhcp_end_address=dhcp_end_address, mirror_type=mirror_type)


def _get_config(**kwargs):
    return '\n'.join(['%s=%s' % (str(k), str(v)) for k, v in kwargs.items()])


class SelfTest(TestCase):
    def test_config(self):
        print get_config(hostname='fuel-pm', domain='local', management_interface='eth0', management_ip='10.0.0.100',
                         management_mask='255.255.255.0', external_interface='eth1', dhcp_start_address='10.0.0.201',
                         dhcp_end_address='10.0.0.254', mirror_type='iso', external_ip='asdf', external_mask='asdff')

# hostname="fuel-pm"
# domain="local"
# mgmt_if="eth0"
# mgmt_ip="10.0.0.100"
# mgmt_mask="255.255.0.0"
# ext_if="eth1"
# dhcp_start_address="10.0.0.201"
# dhcp_end_address="10.0.0.254"
# mirror_type="iso"