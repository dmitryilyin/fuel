require 'spec_helper'

describe service 'openstack-nova-conductor' do
  it { should be_running }
  it { should be_enabled }
end
