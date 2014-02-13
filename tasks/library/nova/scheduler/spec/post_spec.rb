require 'spec_helper'

describe service 'openstack-nova-scheduler' do
  it { should be_running }
  it { should be_enabled }
end
