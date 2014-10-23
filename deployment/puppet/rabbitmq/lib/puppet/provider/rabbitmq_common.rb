require 'rubygems'
require 'puppet'
require 'puppet/util/execution'

module RabbitmqCommon
  def wait_for_rabbitmq(count=120, step=1)
    Puppet.debug "Waiting #{count * step} seconds for RabbitMQ to become online!"
    (0...count).each do |n|
      begin
        Puppet::Util::Execution.execute 'rabbitmqctl status'
      rescue Puppet::ExecutionFailure
        sleep step
      else
        Puppet.debug "RabbitMQ is online after #{n * step} seconds"
        return true
      end
    end
    raise Puppet::Error, "RabbitMQ is not ready after #{count * step} seconds expired!"
  end
end