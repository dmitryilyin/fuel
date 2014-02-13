require 'spec_helper'
require 'rubygems'
require 'facter'

describe 'index file' do
  let(:index_file) do
    case Facter.value(:osfamily)
      when 'RedHat' then '/var/www/html/index.html'
      when 'Debian' then '/var/www/index.html'
    end
  end
  it { file(index_file).should be_file }
  it { file(index_file).should be_readable }
  it { file(index_file).should contain 'Hello World!' }
  it { file(index_file).should be_mode 644 }
  it { file(index_file).should be_owned_by 'root' }
  it { file(index_file).should be_grouped_into 'root' }
end