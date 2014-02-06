require 'spec_helper'

def make_mysql_test_command
  "mysql --batch --user='root' --execute='select 1;'"
end

describe 'mysql admin access check' do
  let (:mysql_test_command) { make_mysql_test_command }
  it { command(mysql_test_command).should return_exit_status 0 }
end