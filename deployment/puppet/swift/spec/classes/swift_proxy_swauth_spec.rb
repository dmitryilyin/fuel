require 'spec_helper'

describe 'swift::proxy::swauth' do

  let :facts do
    {
      :concat_basedir => '/var/lib/puppet/concat'
    }
  end

  let :pre_condition do
    'class { "concat::setup": }
     concat { "/etc/swift/proxy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/20_swift_proxy_swauth"
  end

  it { should contain_package('python-swauth') }

  it { should contain_file(fragment_file).with_content(/[filter:swauth]/) }
  it { should contain_file(fragment_file).with_content(/use = egg:swauth#swauth/) }

  describe 'with defaults' do

    it { should contain_file(fragment_file).with_content(/default_swift_cluster = local#127\.0\.0\.1/) }
    it { should contain_file(fragment_file).with_content(/super_admin_key = swauthkey/) }

  end

  describe 'with overridden endpoint' do

    let :params do
      {:swauth_endpoint => '10.0.0.1'}
    end

    it { should contain_file(fragment_file).with_content(/default_swift_cluster = local#10\.0\.0\.1/) }

  end

  describe 'with overridden admin key' do

    let :params do
      {:swauth_super_admin_key => 'foo'}
    end

    it { should contain_file(fragment_file).with_content(/super_admin_key = foo/) }

  end

end

