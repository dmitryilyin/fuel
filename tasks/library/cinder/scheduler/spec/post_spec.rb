require 'spec_helper'

describe service 'openstack-cinder-scheduler' do
  it { should be_running }
  it { should be_enabled }
end
