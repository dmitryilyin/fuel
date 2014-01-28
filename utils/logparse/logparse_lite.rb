require 'English'
require 'time'

log = []
last_time = nil
top = 10
sum_total = 0.0

def show_seconds(seconds)
  "#{sprintf('%.02f',seconds)} sec (#{sprintf('%.02f',seconds / 60)} min)"
end

while gets
  begin
    # last line. exit this file!
    if ($LAST_READ_LINE =~ /Finished catalog run in (\S+) seconds/)
      total = $1.to_f
      break
    end

    # a puppet line with time
    if ($LAST_READ_LINE =~ /^(\S+)\s+(\S+)\s+(.*)/)
      raw_time = $1
      time = Time.parse $1
      level = $2
      message = $3
      
      # set duration of this line
      if last_time
        duration = time - last_time
      else
        duration = 0.0
      end
      last_time = time
    
      # add record to log  
      line = { :time => time, :message => message, :level => level, :duration => duration, :number => $INPUT_LINE_NUMBER }
      sum_total += duration
      log << line
      # parse next line
      next
    end
    # end line with time

  rescue
    # error. skip this line
    next
  end
end

# OUTPUT

if log.empty?
  puts "No records found!"
  exit 1
end

puts "Top lines:"
number = 1
log.sort_by { |line| line[:duration] }.reverse[0,top].each { |line|
  puts "#{"%02d" % number} - #{show_seconds line[:duration]} #{line[:number]} #{line[:tme]} #{line[:message]}"
  number += 1
}

if total
  puts "Puppet Total: #{show_seconds(total)}"
end
if sum_total
  puts "Sum Total: #{show_seconds(sum_total)}"
end
