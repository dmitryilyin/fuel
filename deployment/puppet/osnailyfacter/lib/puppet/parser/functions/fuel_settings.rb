require 'yaml'
require 'rubygems'
require 'ipaddr'

module Fuel
  def self.nodes_to_hash(nodes, key, value)
    Hash[ nodes.map { |n| [ n[key], n[value] ] } ]
  end

  def self.nodes_collect(nodes, key)
    nodes.inject([]) do |collected, node|
      if yield node
        collected << node[key]
      else
        collected
      end
    end
  end

  def self.ip_sort(ips)
    ips.sort_by { |ip| IPAddr.new ip }
  end

  def self.host_port_list(hosts, port, prefer_host = nil)
    # split hosts by comma if the are provided as a string
    if hosts.is_a? String
      hosts = hosts.split(',').map { |h| h.strip }
    end
    hosts = Array(hosts)

    # rotate hosts array random number of times (host fqdn as a seed)
    if hosts.length > 1
      shake_times = function_fqdn_rand([hosts.length]).to_i
      shake_times.times do
        hosts.push hosts.shift
      end
    end

    # move prefered node to the first position if it's present
    if prefer_host and hosts.include? prefer_host
      hosts.delete prefer_host
      hosts.unshift prefer_host
    end

    hosts.map { |n| "#{n}:#{port}" }.join ', '
  end
end

class Settings
  @settings = {}
  def self.value
    @settings
  end
  def self.[]=(key, value)
    value = Marshal.load Marshal.dump(value)
    @settings.store key, value
  end
  def self.[](key)
    @settings[key]
  end
end

module Puppet::Parser::Functions
  newfunction(
      :fuel_settings,
      :type => :rvalue,
      :doc => <<-EOS
Process the astute.yaml data to the settings structure.
  EOS
  ) do |arguments|
    Puppet::Parser::Functions.autoloader.loadall
    raise(Puppet::ParseError, 'No astute.yaml data provided!') if arguments.size < 1
    data = YAML.load arguments[0]
    raise(Puppet::ParseError, 'Settings was not parsed correctly!') unless data and data.is_a? Hash

    fqdn = lookupvar '::fqdn'
    processorcount = lookupvar('::processorcount').to_i

    node = data['nodes'].find { |n| n['fqdn'] == fqdn }
    raise(Puppet::ParseError, "Node '#{fqdn}' is not defined in the hash structure!") unless node
    Settings['node'] = node

    Settings['use_neutron'] = data.fetch 'quantum', true
    Settings['debug'] = data.fetch 'debug', false
    Settings['verbose'] = data.fetch 'verbose', true

    Settings['log_facility'] = {
        'glance' => 'LOG_LOCAL2',
        'cinder' => 'LOG_LOCAL3',
        'neutron' => 'LOG_LOCAL4',
        'nova' => 'LOG_LOCAL6',
        'keystone' => 'LOG_LOCAL7',
        'murano' => 'LOG_LOCAL0',
        'heat' => 'LOG_LOCAL0',
        'sahara' => 'LOG_LOCAL0',
        'ceilometer' => 'LOG_LOCAL0',
        'ceph' => 'LOG_LOCAL0',
    }

    Settings['nova_rate_limits'] = {
        'POST' => 100000,
        'POST_SERVERS' => 100000,
        'PUT' => 1000,
        'GET' => 100000,
        'DELETE' => 100000
    }

    Settings['cinder_rate_limits'] = {
        'POST' => 100000,
        'POST_SERVERS' => 100000,
        'PUT' => 100000,
        'GET' => 100000,
        'DELETE' => 100000,
    }

    function_prepare_network_config [ data['network_scheme'] ]

    Settings['default_gateway'] = node['default_gateway']

    if Settings['use_neutron']
      Settings['internal_interface'] = function_get_network_role_property ['management', 'interface']
      Settings['internal_address'] = function_get_network_role_property ['management', 'ipaddr']
      Settings['internal_netmask'] = function_get_network_role_property ['management', 'netmask']

      Settings['public_interface'] = function_get_network_role_property ['ex', 'interface']
      Settings['public_address'] = function_get_network_role_property ['ex', 'ipaddr']
      Settings['public_netmask'] = function_get_network_role_property ['ex', 'netmask']

      Settings['storage_interface'] = function_get_network_role_property ['storage', 'interface']
      Settings['storage_address'] = function_get_network_role_property ['storage', 'ipaddr']
      Settings['storage_netmask'] = function_get_network_role_property ['storage', 'netmask']

      Settings['novanetwork_params'] = {}
      Settings['neutron_config'] = data['quantum_settings']
      Settings['network_provider'] = 'neutron'

      nsx_config = Settings['nsx_plugin']
      if nsx_config and nsx_config['metadata']['enabled']
        Settings['use_vmware_nsx'] = true
        Settings['neutron_nsx_config'] = nsx_config
      end
    else
      Settings['internal_address'] = node['internal_address']
      Settings['internal_netmask'] = node['internal_netmask']

      Settings['public_address'] = node['public_address']
      Settings['public_netmask'] = node['public_netmask']

      Settings['storage_address'] = node['storage_address']
      Settings['storage_netmask'] = node['storage_netmask']
    end

    #
    # settings['neutron_config']     = {}
    # $novanetwork_params = hiera('novanetwork_parameters')
    # $network_size       = $novanetwork_params['network_size']
    # $num_networks       = $novanetwork_params['num_networks']
    # $vlan_start         = $novanetwork_params['vlan_start']
    # $network_provider   = 'nova'
    # $network_config = {
    #     'vlan_start'     => $vlan_start,
    # }
    #settings['network_manager']    = "nova.network.manager.${novanetwork_params['network_manager']}"

    #?
    Settings['queue_provider'] = 'rabbitmq'
    Settings['custom_mysql_setup_class'] = 'galera'
    #?

    Settings['nova_settings'] = {}
    Settings['nova_settings']['interval'] = '60'
    Settings['nova_settings']['service_down_time'] = '180'

    Settings['primary_controller_nodes'] = data['nodes'].select { |n| n['role'] == 'primary_controller' }
    Settings['secondary_controller_nodes'] = data['nodes'].select { |n| n['role'] == 'controller' }
    Settings['controller_nodes'] = Settings['primary_controller_nodes'] + Settings['secondary_controller_nodes']
    Settings['controller_internal_address_hash'] = Fuel.nodes_to_hash Settings['controller_nodes'], 'name', 'internal_address'
    Settings['controller_public_address_hash']   = Fuel.nodes_to_hash Settings['controller_nodes'], 'name', 'public_address'
    Settings['controller_storage_address_hash']  = Fuel.nodes_to_hash Settings['controller_nodes'], 'name', 'storage_address'

    Settings['controller_hostnames'] = Fuel.nodes_collect(Settings['controller_nodes'], 'name') { |n| n['name'] }
    Settings['controller_internal_addresses'] = Fuel.ip_sort(Settings['controller_internal_address_hash'].values)
    Settings['controller_public_address'] = data['public_vip']
    Settings['controller_management_address'] = data['management_vip']
    Settings['roles'] = Fuel.nodes_collect(data['nodes'], 'role') { |n| n['uid'] == data['uid'] }

    Settings['amqp'] = {}
    Settings['amqp']['port'] = '5672'
    Settings['amqp']['hosts'] = Fuel.host_port_list Settings['controller_internal_addresses'], Settings['amqp']['port'], Settings['internal_address']
    Settings['amqp']['rabbit_ha_queues'] = false
    Settings['amqp']['bind_ip_address'] = 'UNSET'
    Settings['amqp']['bind_port'] = Settings['amqp']['port']
    Settings['amqp']['cluster_nodes'] = Settings['controller_hostnames'].dup

    Settings['sqlalchemy'] = {}
    Settings['sqlalchemy']['max_pool_size'] =  [processorcount * 5, 30].min
    Settings['sqlalchemy']['max_overflow'] = [processorcount * 5, 60].min
    Settings['sqlalchemy']['max_retries '] = '-1'
    Settings['sqlalchemy']['idle_timeout'] = '3600'

    nova_db_password = data['nova']['db_password']
    Settings['nova_sql_connection'] =
        "mysql://nova:#{nova_db_password}@#{Settings['controller_management_address']}/nova?read_timeout=60"

    if Settings['roles'].include?('cinder') and data['storage']['volumes_lvm']
      Settings['manage_volumes'] = 'iscsi'
    elsif Settings['roles'].include?('cinder') and data['storage']['volumes_vmdk']
      Settings['manage_volumes'] = 'vmdk'
    elsif data['storage']['volumes_ceph']
      Settings['manage_volumes'] = 'ceph'
    else
      Settings['manage_volumes'] = false
    end

    if data['storage']['images_ceph']
      Settings['glance_backend'] = 'ceph'
      Settings['glance_known_stores'] = [ 'glance.store.rbd.Store', 'glance.store.http.Store' ]
    elsif data['storage']['images_vcenter']
      Settings['glance_backend'] = 'vmware'
      Settings['glance_known_stores'] = [ 'glance.store.vmware_datastore.Store', 'glance.store.http.Store' ]
    else
      Settings['glance_backend'] = 'file'
      Settings['glance_known_stores'] = false
    end

    Settings.value.to_yaml + "\n"

  end
end

# vim: set ts=2 sw=2 et :
