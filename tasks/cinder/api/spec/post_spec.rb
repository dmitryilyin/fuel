require 'spec_helper'

describe service 'openstack-cinder-api' do
  it { should be_running }
  it { should be_enabled }
end
