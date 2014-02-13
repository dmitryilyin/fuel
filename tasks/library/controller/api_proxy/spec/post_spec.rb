require 'spec_helper'

describe command("curl -fx 'http://127.0.0.1:8888' 127.0.0.1") do
  it { should return_stdout /301 Moved Permanently/ }
  it { should return_exit_status 0 }
end
