require 'spec_helper'

describe command('rabbitmqctl list_users') do
  it { should return_stdout /^nova\s+\[administrator\]/ }
  it { should return_exit_status 0 }
end
