require 'set'
Puppet::Type.type(:rabbitmq_user).provide(:rabbitmqctl) do

  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqctl => 'rabbitmqctl'
  else
    has_command(:rabbitmqctl, 'rabbitmqctl') do
      environment :HOME => "/tmp"
    end
  end

  defaultfor :feature => :posix

  ADMIN_TAG = 'administrator'

  # get the RabbitMQ version number
  # @return [Float]
  def self.version
    return @version if @version
    status_text = rabbitmqctl '-q', 'status'
    status_text.split("\n").each do |line|
      begin
        if line =~ %r{"RabbitMQ","([\d\.]+)"}
          version = $1.split('.')
          @version =  "#{version[0]}.#{version[1..-1].join ''}".to_f
          return @version
        end
      rescue
        return @version = nil
      end
    end
    @version = nil
  end

  # reset saved version number
  def self.version_reset
    @version = nil
  end

  # check if this version supports tags
  # @return [TrueClass,FalseClass]
  def self.tag_support?
    self.version && self.version > 2.41
  end

  # get the list of users and their tags
  # @return [Hash<String => Set>]
  def self.users
    user_list = rabbitmqctl '-q', 'list_users'
    users = {}
    user_list.split("\n").each do |line|
      if line =~ %r{(.*?)\[(.*?)\]}
        user = $1.strip
        tags = $2.split(',').map { |tag| tag.strip }
        users.store user, Set.new(tags)
      elsif line =~ %r{^(\S+)\s+(true|false)}
        user = $1.strip
        if $2 == 'true'
          tags = [ADMIN_TAG]
        else
          tags = []
        end
        users.store user, Set.new(tags)
      end
    end
    users
  end

  # create provider instance for every resource found.
  # User for resource discovery and can be used for prefetch
  # FIXME: discovery will not work because type instances cannot be created without password
  def self.instances
    self.users.keys.map do |user|
      new({ :name => user })
    end
  end

  # take hash of type instances from catalog and try
  # to match them with present provider if their names are same
  # @param catalog_resources [Hash]
  def self.prefetch(catalog_resources)
    Puppet.debug 'Call: prefetch rabbitmq_user'
    present_resources = self.instances
    catalog_resources.keys.each do |resource_name|
      found_provider = present_resources.find { |instance| instance.name == resource_name }
      if found_provider
        catalog_resources[resource_name].provider = found_provider
      end
    end
  end

  # create this user and set it's tags
  def create
    Puppet.debug "Call: create rabbitmq_user '#{resource[:name]}'"
    rabbitmqctl 'add_user', resource[:name], resource[:password]
    self.tags = resource[:tags]
  end

  # delete this user
  def destroy
    Puppet.debug "Call: destroy rabbitmq_user '#{resource[:name]}'"
    rabbitmqctl 'delete_user', resource[:name]
  end

  # check if this users exists
  # @return [TrueClass,FalseClass]
  def exists?
    Puppet.debug "Call: exists? rabbitmq_user '#{resource[:name]}'"
    out = self.class.users.key? resource[:name]
    Puppet.debug "Return: #{out.inspect} (#{out.class})"
    out
  end

  # get an array of this user's tags
  # reject admin tag because it's implicitly sets by admin => true
  # @return [Array<String>]
  def tags
    Puppet.debug "Call: tags rabbitmq_user '#{resource[:name]}'"
    out = get_user_tags.entries.reject { |tag| tag == ADMIN_TAG }.sort
    Puppet.debug "Return: #{out.inspect} (#{out.class})"
    out
  end

  # set tags for this user
  # implicitly add admin tag if the user is admin
  # @param tags [Array<String>]
  def tags=(tags)
    Puppet.debug "Call: tags= rabbitmq_user '#{resource[:name]}' with '#{tags.inspect} (#{tags.class})'"
    user_tags = Set.new tags
    user_tags.add ADMIN_TAG if get_user_tags.member?(ADMIN_TAG) || (resource[:admin] == :true)
    if self.class.tag_support?
      rabbitmqctl 'set_user_tags', resource[:name], user_tags.entries.sort
    else
      set_unset_admin user_tags
    end
  end

  # get information if this user is set to be administrator
  # by cheking if administrator tag is present
  # @return [:true,:false]
  def admin
    Puppet.debug "Call: admin rabbitmq_user '#{resource[:name]}'"
    out = self.class.users.fetch(resource[:name], []).include? ADMIN_TAG
    out = out.to_s.to_sym
    Puppet.debug "Return: #{out.inspect} (#{out.class})"
    out
  end

  # set this user to be the administrator
  # by adding administrtor tag
  # or removing the tag to remove the admin status
  # @param state [:true,:false]
  def admin=(state)
    user_tags = get_user_tags
    if state == :true
      user_tags.add ADMIN_TAG
    else
      user_tags.delete ADMIN_TAG
    end
    if self.class.tag_support?
      rabbitmqctl 'set_user_tags', resource[:name], user_tags.entries.sort
    else
      set_unset_admin user_tags
    end
  end

  # old admin control method support
  # @param tags [Set<String>]
  def set_unset_admin(tags)
    if tags.include? ADMIN_TAG
      rabbitmqctl 'set_admin', resource[:name]
    else
      rabbitmqctl 'clear_admin', resource[:name]
    end
  end

  # get a set of tags of this user
  # @return [Set<String>]
  def get_user_tags
    self.class.users.fetch resource[:name], Set.new
  end
end