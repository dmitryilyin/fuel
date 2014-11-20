Puppet::Type.newtype(:haproxy_backend_online) do
  desc  'Wait for HAProxy backend to become online'

  newparam(:name) do
  end

  newparam(:url) do
    desc 'Use this url to get CSV status'
  end

  newparam(:socket) do
    desc 'Use this socket to get CSV status'
  end

  newparam(:backend) do
    desc 'The name of HAProxy backend to monitor'
  end

  newparam(:status) do
    desc 'Wait for what status? present - backend should exist, up - backend should be online, down - backend should be offline'
    newvalues :up, :down, :present
    defaultto :up
  end

  def validate
    unless self[:socket].nil? ^ self[:url].nil?
      raise 'You should give either url or socket to get HAProxy status and not both!'
    end
    if self[:backend].nil?
      raise 'You should provide the HAProxy backend name to monitor!'
    end
  end

end