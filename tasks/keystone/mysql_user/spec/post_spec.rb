require 'spec_helper'
require 'yaml'

def make_mysql_test_command
  astute_yaml = '/etc/astute.yaml'
  yaml = File.open astute_yaml, 'r'
  fuel_settings = YAML::load yaml
  yaml.close
  keystone_hash = fuel_settings['keystone']

  db_user = 'keystone'
  db_name = 'keystone'
  db_host = '127.0.0.1'
  db_password = keystone_hash['db_password']
  
  "mysql --batch --user='#{db_user}' --password='#{db_password}' --database='#{db_name}' --host='#{db_host}' --execute='select 1;'"
end

describe 'mysql keystone user access check' do
  let (:mysql_test_command) { make_mysql_test_command }
  it "should be successful" do
    command(mysql_test_command).should return_exit_status 0
  end
end
