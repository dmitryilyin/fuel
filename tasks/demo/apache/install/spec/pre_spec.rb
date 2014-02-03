require 'spec_helper'
require 'rubygems'
require 'facter'

describe 'server' do
  let(:supported_osfamily) { %w(Debian RedHat) }
  let(:supported_architecture) { %w(amd64) }

  let(:osfamily) { Facter.value :osfamily }
  let(:architecture) { Facter.value :architecture }

  it 'os should be supported' do
    supported_osfamily.should include osfamily
  end

  it 'architecture should be supported' do
    supported_architecture.should include architecture
  end

  describe selinux do
    it { should be_disabled }
  end

end
