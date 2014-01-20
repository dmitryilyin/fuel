require 'spec_helper'

describe file('/tmp') do
  it { should be_directory }
  it { should be_writable }
end
