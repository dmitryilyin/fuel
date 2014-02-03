require 'spec_helper'
require 'rubygems'
require 'facter'

describe file '/var' do
  it { should be_directory }
  it { should be_writable }
end