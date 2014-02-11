require 'spec_helper'

describe service 'rabbitmq-server' do
  it { should be_running }
  it { should be_enabled }
end
