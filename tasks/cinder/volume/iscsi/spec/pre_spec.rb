require 'spec_helper'

describe file '/etc/cinder/cinder.conf' do
  it { should be_file }
  it { should be_readable }
end
