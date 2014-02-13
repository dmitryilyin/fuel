require 'spec_helper'

describe service 'openstack-nova-xvpvncproxy' do
  it { should be_running }
  it { should be_enabled }
end
