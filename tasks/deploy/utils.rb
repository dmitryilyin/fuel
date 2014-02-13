module Deploy
  
  # different utility functions
  # should be static
  class Utils

    # this method parses xunit report to human readable form
    # @param xunit [String]
    # @return [String]
    def self.xunit_to_list(xunit)
      require 'rubygems'
      require 'rexml/document'
      include REXML
  
      xml = REXML::Document.new xunit
      raise 'Could not parse file!' unless xml
  
      text = ''
      testsuite = xml.root.elements['/testsuite']
      errors = testsuite.attributes['failures'].to_i
      testcases = xml.root.elements.to_a('testcase')
  
      testcases.each do |tc|
        success = true
        message = ''
        failures = tc.elements.to_a('failure')
        if failures.any?
          success = false
          message = failures.first.texts.join.gsub(/\s+/,' ')
        end
        text += "#{tc.attributes['name']} | #{success ? 'OK' : 'FAIL'} | #{message}\n"
      end
  
      text += '-' * 20 + "\n"
      text += "Errors: #{errors}\n"
      return { :errors => errors, :text => text }
    end

    # generate xunit xml from test cases structure
    # @param testcases [Array<Hash>]
    # @return [String]
    def self.make_xunit(testcases)
      testcases = [testcases] unless testcases.kind_of? Array
      raise 'No testcases! There should be at least one.' unless testcases.any?
      tests = testcases.length
      failures = testcases.select { |tc| tc[:failure] }.length
      errors = 0
      require 'time'
      timestamp = Time.now.iso8601
      time = testcases.inject(0.0) { |t, tc| t + tc[:time] || 0.0 }
      xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      xml += "<testsuite tests=\"#{tests}\" failures=\"#{failures}\" errors=\"#{errors}\" timestamp=\"#{timestamp}\" time=\"#{time}\">\n"
      testcases.each do |tc|
        raise "Task #{tc.inspect} has no classname" unless tc[:classname]
        xml += "<testcase classname=\"#{tc[:classname]}\" time=\"#{tc[:time] || 0.0}\" name=\"#{tc[:name] || tc[:classname]}\">\n"
        if tc[:failure]
          raise "Task #{tc.inspect} has no failure message" unless tc[:failure][:message]
          xml += "<failure type=\"#{tc[:failure][:type] || 'Task::Error'}\" message=\"#{tc[:failure][:message]}\">\n"
          xml += "<![CDATA[#{tc[:failure][:text] || tc[:failure][:message]}]]>\n"
          xml += "</failure>\n"
        end
        xml += "</testcase>\n"
      end
      xml += "</testsuite>\n"
      xml
    end
  
    # this method parses json report to human readable form
    # @param json [String]
    # @return [String]
    def self.json_to_list(json)
      # TODO implement
      p json
      return { :errors => 0, :text => '' }
    end

    # generate json from test cases structure
    # # @param testcases [Array<Hash>]
    # @return [String]
    def self.make_json(testcases)
      # TODO implement
      p testcases
      return ''
    end
  
    # print a line of the task list
    # @param task [Deploy::Task]
    # @param name_length [Numeric]
    def self.print_task_line(task, name_length)
      line = ''
      line += task.name.to_s.ljust name_length if task.name
      line += task.comment.to_s if task.comment
      puts line unless line.empty?
    end
  
    # print the entire list of tasks
    # @param tasks [Array<Deploy::Task>]
    def self.print_tasks_list(tasks)
      raise 'Deploy list should be Array!' unless tasks.is_a? Array
      return nil unless tasks.any?
      max_length = tasks.inject 0 do |ml, t|
        len = t.name.length
        len > ml ? len : ml
      end
      tasks.each { |t| self.print_task_line t, max_length + 1 }
    end

    # output debug string
    # @param message [String]
    def self.debug(message)
      STDERR.puts message.to_s if Deploy::Config[:debug]
    end

    # convert hash's keys to symbols
    # @param hash [Hash]
    def self.symbolize_hash(hash)
      hash.each do |k,v|
        next if k.is_a? Symbol
        hash.delete k
        hash.store k.to_sym, v
      end
    end

  end # class

end # module
