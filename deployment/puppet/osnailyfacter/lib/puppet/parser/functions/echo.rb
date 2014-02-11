Puppet::Parser::Functions::newfunction(:echo, :doc => <<-EOS
echo var and its type
    EOS
) do |argv|
  value = argv[0]
  comment = argv[1]
  msg = "#{value.class}: #{value.inspect}"
  if comment
    msg = "#{comment} " + msg
  end
  puts msg
end
