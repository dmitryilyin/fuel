require 'puppet'
require 'mocha'
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Type.type(:rabbitmq_user).provider(:rabbitmqctl)
describe provider_class do
  before :each do
    @resource = Puppet::Type::Rabbitmq_user.new(
        {:name => 'foo', :password => 'bar'}
    )
    @provider = provider_class.new(@resource)
    @provider.class.stubs(:tag_support?).returns true
  end
  it 'can get rabbitmq-server version' do
    @provider.class.version_reset
    @provider.class.expects(:rabbitmqctl).with('-q', 'status').returns <<-EOT
{running_applications,[{rabbit,"RabbitMQ","3.3.5"}
    EOT
    expect(@provider.class.version).to eq(3.35)
    @provider.class.version_reset
    @provider.class.expects(:rabbitmqctl).with('-q', 'status').returns <<-EOT
{running_applications,[{rabbit,"RabbitMQ","2.4.1"}
    EOT
    expect(@provider.class.version).to eq(2.41)
  end

  it 'can check if tags are supported' do
    @provider.class.unstub(:tag_support?)
    @provider.class.stubs(:version).returns 3.35
    expect(@provider.class.tag_support?).to eq(true)
    @provider.class.stubs(:version).returns 2.41
    expect(@provider.class.tag_support?).to eq(false)
  end

  it 'should match user names' do
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo []
    EOT
    @provider.exists?.should == true
  end
  it 'should match user names with 2.4.1 syntax' do
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
admin	true
guest	false
test	true
dev false
foo true
    EOT
    @provider.exists?.should == true
  end
  it 'should not match if no users on system' do
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
    EOT
    @provider.exists?.should == false
  end
  it 'should not match if no matching users on system' do
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
fooey
    EOT
    @provider.exists?.should == false
  end
  it 'should create user and set password' do
    @resource[:password] = 'bar'
    @provider.expects(:rabbitmqctl).with('add_user', 'foo', 'bar')
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
one []
    EOT
    @provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', [])
    @provider.create
  end
  it 'should create user, set password and set to admin' do
    @resource[:password] = 'bar'
    @resource[:admin] = 'true'
    @provider.expects(:rabbitmqctl).with('add_user', 'foo', 'bar')
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
one []
    EOT
    @provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w(administrator))
    @provider.create
  end
  it 'should call rabbitmqctl to delete' do
    @provider.expects(:rabbitmqctl).with('delete_user', 'foo')
    @provider.destroy
  end
  it 'should be able to retrieve admin value' do
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo [administrator]
    EOT
    @provider.admin.should == :true
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
one [administrator]
foo []
    EOT
    @provider.admin.should == :false
  end
  it 'should be able to set admin value' do
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo   []
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
    EOT
    @provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w(administrator))
    @provider.admin = :true
  end
  it 'should not interfere with existing tags on the user when setting admin value' do
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo   [bar, baz]
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
    EOT
    @provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w(bar baz administrator).sort)
    @provider.admin = :true
  end
  it 'should be able to unset admin value' do
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo     [administrator]
guest   [administrator]
icinga  []
    EOT
    @provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', [])
    @provider.admin = :false
  end
  it 'should not interfere with existing tags on the user when unsetting admin value' do
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo   [administrator, bar, baz]
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
    EOT
    @provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w(bar baz).sort)
    @provider.admin=:false
  end

  it 'should clear all tags on existing user' do
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
one [administrator]
foo [tag1,tag2]
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
    EOT
    @provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', [])
    @provider.tags = []
  end

  it 'should set multiple tags' do
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
one [administrator]
foo []
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
    EOT
    @provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w(tag1 tag2))
    @provider.tags = %w(tag1 tag2)
  end

  it 'should clear tags while keep admin tag' do
    @resource[:admin]  = true
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
one [administrator]
foo [administrator, tag1, tag2]
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
    EOT
    @provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w(administrator))
    @provider.tags = []
  end

  it 'should change tags while keep admin tag' do
    @resource[:admin]  = true
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
one [administrator]
foo [administrator, tag1, tag2]
icinga  [monitoring]
kitchen []
kitchen2        [abc, def, ghi]
    EOT
    @provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w(administrator tag1 tag3 tag7))
    @provider.tags = %w(tag1 tag7 tag3)
  end

  it 'should create user with tags and without admin' do
    @resource[:tags] = %w(tag1 tag2)
    @provider.expects(:rabbitmqctl).with('add_user', 'foo', 'bar')
    @provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w(tag1 tag2))
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo []
    EOT
    @provider.create
  end

  it 'should create user with tags and with admin' do
    @resource[:tags] = %w(tag1 tag2)
    @resource[:admin]  = true
    @provider.expects(:rabbitmqctl).with('add_user', 'foo', 'bar')
    @provider.class.expects(:rabbitmqctl).with('-q', 'list_users').returns <<-EOT
foo []
    EOT
    @provider.expects(:rabbitmqctl).with('set_user_tags', 'foo', %w(administrator tag1 tag2))
    @provider.create
  end

end