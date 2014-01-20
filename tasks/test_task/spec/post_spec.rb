require 'spec_helper'

describe file('/tmp/test') do
  it { should be_file }
  it { should be_readable }
  it { should contain 'test file' }
  it { should be_mode 644 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
end
