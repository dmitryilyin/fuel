require 'find'
require 'tasks'
Rake::TaskManager.record_task_metadata = true

Tasks.config[:report_dir]

# create rake task and subtasks
def make_task(file)
  directory = File.dirname file
  new_task = Tasks::Task.new directory
  action = File.basename file
  name = new_task.name
  namespace name do
    task action do
      puts "Run task: #{name} action: #{action}"
      File.chmod 0755, file unless File.stat(file).executable?
      system file
    end
    task "#{action}/report" do
      new_task.report_read action
    end
    task "#{action}/raw" do
      new_task.report_raw action
    end
    task "#{action}/remove" do
      new_task.report_remove action
    end
    task "#{action}/success" do
      new_task.success? action
    end
  end

  unless Rake.application.tasks.select { |t| t.name == name }.any?
    if new_task.title
      desc new_task.title
    else
      desc "#{name} task"
    end
    task name do
      all_tasks = Rake.application.tasks.map { |t| t.name }
      puts "Run full task: #{name}"
      if all_tasks.include? "#{name}:pre"
        Rake::Task["#{name}:pre"].invoke
        raise "Pre-deployment test of task \"#{name}\" failed!" if new_task.fail? 'pre'
        new_task.report_read 'pre'
      end
      Rake::Task["#{name}:run"].invoke if all_tasks.include? "#{name}:run"
      if all_tasks.include? "#{name}:post"
        Rake::Task["#{name}:post"].invoke
        new_task.report_read 'post'
      end
    end
    task "#{name}/info" do
      puts new_task.readme
    end
  end

end

# deploy preset of tasks
# argument start_task can set fist task to do
# /list can display tasks in preset
def deploy_preset(name, tasks, comment = nil)
  desc comment ? comment : "Preset deploymnet: #{name}"
  task "preset/#{name}", :start_task do |t, args|
    fail "No tasks in preset #{name}!" unless tasks.respond_to?(:each) && tasks.any?
    start_task_number = nil
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
Dir.chdir Tasks.config[:task_dir] or raise "Cannot change directory to #{Tasks.config[:task_dir]}"

Find.find('.') do |path|
  next unless File.file? path
  next unless path.end_with? '/run' or path.end_with? '/pre' or path.end_with? '/post'
  make_task path
end


# print a line of the task list
def print_task_line(task, name_length)
  line = ''
  line += task.name.to_s.ljust name_length if task.name
  line += task.comment.to_s if task.comment
  puts line unless line.empty?
end

# print the entire list of tasks
def print_tasks_list(tasks)
  raise 'Tasks list should be Array!' unless tasks.is_a? Array
  return nil unless tasks.any?
  max_length = tasks.inject 0 do |ml, t|
    len = t.name.length
    ml = len > ml ? len : ml
  end
  tasks.each { |t| print_task_line t, max_length + 1 }
end

# show main tasks
task 'list' do
  tasks = Rake.application.tasks
  presets = tasks.select { |t| t.comment and t.name.start_with? 'preset/' }
  main_tasks = tasks.select { |t| t.comment and not t.name.start_with? 'preset/' }
  print_tasks_list presets
  puts
  print_tasks_list main_tasks
end

# show main tasks by default
task 'list/all' do
  tasks = Rake.application.tasks
  presets = tasks.select { |t| t.name.start_with? 'preset/' }
  main_tasks = tasks.select { |t| !t.name.start_with? 'preset/' }
  print_tasks_list presets
  puts
  print_tasks_list main_tasks
end

task :default => [ :list ]