require 'spec_helper'
require 'yaml'

def make_mysql_test_command
  astute_yaml = '/etc/astute.yaml'
  fuel_settings = YAML::load_file astute_yaml
  cinder_hash = fuel_settings['cinder']

  db_user = 'cinder'
  db_name = 'cinder'
  db_host = '127.0.0.1'
  db_password = cinder_hash['db_password']

  "mysql --batch --user='#{db_user}' --password='#{db_password}' --database='#{db_name}' --host='#{db_host}' --execute='select 1;'"
end

describe 'mysql cinder user access check' do
  let (:mysql_test_command) { make_mysql_test_command }
  it "should be successful" do
    command(mysql_test_command).should return_exit_status 0
  end
end
