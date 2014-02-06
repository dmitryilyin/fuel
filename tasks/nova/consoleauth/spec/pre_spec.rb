require 'spec_helper'

describe file '/etc/nova/nova.conf' do
  it { should be_file }
end
