require 'spec_helper'

describe service 'openstack-keystone' do
  it { should be_running }
  it { should be_enabled }
end
