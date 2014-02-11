require 'spec_helper'

describe file '/root/openrc' do
  it { should be_file }
  it { should be_readable }
  it { should contain 'OS_USERNAME' }
  it { should contain 'OS_PASSWORD' }
end
