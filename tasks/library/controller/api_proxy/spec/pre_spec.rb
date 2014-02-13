require 'spec_helper'

describe service 'httpd' do
  it { should be_running }
  it { should be_enabled }
end
