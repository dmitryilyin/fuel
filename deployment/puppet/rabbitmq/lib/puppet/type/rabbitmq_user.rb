Puppet::Type.newtype(:rabbitmq_user) do
  desc 'Native type for managing rabbitmq users'

  ensurable do
    defaultto(:present)
    newvalue(:present) do
      provider.create
    end
    newvalue(:absent) do
      provider.destroy
    end
  end

  autorequire(:service) { 'rabbitmq-server' }

  newparam(:name, :namevar => true) do
    desc 'Name of user'
    newvalues(/^\S+$/)
  end

  # there is no way to extract password or its hash
  newparam(:password) do
    desc 'User password to be set *on creation*'
    defaultto do
      raise ArgumentError, 'Must set password when creating user'
    end
  end

  newproperty(:admin) do
    desc 'rather or not user should be an admin'
    newvalues(/true|false/)
    newvalues(:true, :false)
    munge do |value|
      # converting to_s incase its a boolean
      value.to_s.to_sym
    end
    defaultto :false
  end

  newproperty(:tags, :array_matching => :all) do
    desc 'additional tags for the user'

    # use exact array matching
    # admin tag is bypassed by the provider
    def insync?(is)
      is.sort == should.sort
    end

  end

end