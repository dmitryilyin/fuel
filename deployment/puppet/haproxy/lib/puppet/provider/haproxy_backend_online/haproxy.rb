Puppet::Type.type(:haproxy_backend_online).provide(:haproxy) do
  desc 'Wait for HAProxy backend to become online'

  def csv
    if @resource[:socket]
      get_csv_unix
    else
      get_csv_web
    end
  end

  def get_csv_url

  end

  def get_csv_web

  end

  def status

  end

  def exists?

  end

  def get_csv_unix
    csv = ''
    socket = @resource[:socket]
    begin
      UNIXSocket.open(socket) do |opened_socket|
        opened_socket.puts 'show stat'
        loop do
          line = opened_socket.gets
          break unless line
          csv << line
        end
      end
    rescue
      nil
    end
    csv
  end

end
