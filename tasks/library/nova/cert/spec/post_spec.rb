require 'spec_helper'

describe service 'openstack-nova-cert' do
  it { should be_running }
  it { should be_enabled }
end
