require 'tasks'

t = Tasks::Task.new('/etc/puppet/tasks/example')

t.pre
t.report_read 'pre'

t.run
t.report_read 'run'

t.post
t.report_read 'post'
