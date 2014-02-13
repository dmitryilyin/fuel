require 'spec_helper'

describe service 'mysql' do
  it { should be_running }
  it { should be_enabled }
end
