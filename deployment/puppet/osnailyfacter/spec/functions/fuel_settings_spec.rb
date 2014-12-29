require 'spec_helper'

describe 'the fuel_settings function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:neutron_astute_yaml) { File.read File.join File.dirname(__FILE__), 'neutron_astute.yaml' }

  it 'should exist' do
    expect(
        Puppet::Parser::Functions.function('amqp_hosts')
    ).to eq('function_amqp_hosts')
  end

  it 'should parse astute.yaml' do
    scope.stubs(:lookupvar).with('::fqdn').returns 'node-4'
    scope.stubs(:lookupvar).with('::processorcount').returns '4'

    scope.function_fuel_settings([neutron_astute_yaml])
  end



end
