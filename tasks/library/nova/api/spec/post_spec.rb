require 'spec_helper'

describe service 'openstack-nova-api' do
  it { should be_running }
  it { should be_enabled }
end
