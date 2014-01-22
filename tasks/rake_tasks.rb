require 'find'
require 'tasks'
require 'parse_xunit'
Rake::TaskManager.record_task_metadata = true

TASKS_LOGS = '/var/log/tasks'
TASKS_RUNS = '/var/run/tasks'
TASKS_DIR = File.dirname(File.expand_path(__FILE__))

# create rake task and subtasks
def make_task(task_name, path, task_type, xml_name)
  namespace task_name do
    task task_type do
      puts "Run task: #{task_name} action: #{task_type}"
      system path
    end
    task "#{task_type}/log" do
      xml = File.join TASKS_LOGS, task_name, xml_name
      if File.exists? xml
        parse_xunit xml
      else
        puts 'There is no report file for this task!'
        exit 1
      end
    end
    task "#{task_type}/xml" do
      xml = File.join TASKS_LOGS, task_name, xml_name
      if File.exists? xml
        xml_content = File.read xml
        puts xml_content
      else
        puts 'There is no report file for this task!'
        exit 1
      end
    end
  end
end

# deploy preset of tasks
# argument start_task can set fist task to do
# /list can display tasks in preset
def deploy(name, tasks)
  desc "Preset deploymnet: #{name}"
  task "preset/#{name}", :start_task do |t, args|
    fail "No tasks in preset #{name}!" unless tasks.respond_to?(:each) && tasks.any?
    start_task_number = tasks.index(args.start_task) if args.start_task
    if start_task_number && start_task_number > 0
      tasks = tasks.drop(start_task_number || 0)
    end
    tasks.each do |task|
      Rake::Task[task].invoke
    end
  end
  task "preset/#{name}/list" do
    tasks.each_with_index do |task, num|
      puts "#{num + 1} #{task}"
    end
  end
end

##############################################################

# gather all tasks as rake jobs
Dir.chdir(TASKS_DIR) || exit(1)
Find.find('.') do |path|
  next unless File.file?(path)
  next unless path.end_with?('/run') or path.end_with?('/pre') or path.end_with?('/post')

  path.sub!('./','')
  task_name = File.dirname(path)
  task_name.sub!('/','::')

  if path.end_with?('/run')
    make_task task_name, path, 'run', 'run.xml'
  end

  if path.end_with?('/pre')
    make_task task_name, path, 'pre', 'pre.xml'
  end

  if path.end_with?('/post')
    make_task task_name, path, 'post', 'post.xml'
  end

  if Rake.application.tasks.select { |task| task.name == task_name }.empty?
    desc "#{task_name} task"
    task task_name do
      puts "Run full task: #{task_name}"
      Rake::Task["#{task_name}:pre"].invoke
      Rake::Task["#{task_name}:run"].invoke
      Rake::Task["#{task_name}:post"].invoke
    end
  end

end

# show main tasks by default
task :default do
  tasks = Rake.application.tasks
  tasks.each do |t|
    puts "#{t.name} (#{t.comment})" if t.comment
  end
end
