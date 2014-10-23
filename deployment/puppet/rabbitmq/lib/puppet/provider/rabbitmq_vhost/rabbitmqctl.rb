Puppet::Type.type(:rabbitmq_vhost).provide(:rabbitmqctl) do

  if Puppet::PUPPETVERSION.to_f < 3
    commands :rabbitmqctl => 'rabbitmqctl'
  else
     has_command(:rabbitmqctl, 'rabbitmqctl') do
       environment :HOME => "/tmp"
     end
  end

  def self.rabbitmqctl_safe(timeout=120, *args)
    Timeout::timeout(timeout) do
      loop do
        begin
          return list = rabbitmqctl(*args)
        rescue Puppet::ExecutionFailure => e
          Puppet::debug("RabbitMQ is not ready, retrying.\nError message: #{e}")
        end
        sleep 2
      end
    end
    raise Puppet::Error, "RabbitMQ is not ready after timeout #{timeout} expired"
  end

  def self.instances
    rabbitmqctl_safe('list_vhosts').split(/\n/)[1..-2].map do |line|
      if line =~ /^(\S+)$/
        new(:name => $1)
      else
        raise Puppet::Error, "Cannot parse invalid user line: #{line}"
      end
    end
  end

  def create
    rabbitmqctl_safe('add_vhost', resource[:name])
  end

  def destroy
    rabbitmqctl_safe('delete_vhost', resource[:name])
  end

  def exists?
    out = rabbitmqctl_safe('list_vhosts').split(/\n/)[1..-2].detect do |line|
      line.match(/^#{Regexp.escape(resource[:name])}$/)
    end
  end

end
