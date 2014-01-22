require 'find'
require 'tasks'
Rake::TaskManager.record_task_metadata = true

Tasks.config[:report_dir]

# create rake task and subtasks
def make_task(file)
  directory = File.dirname file
  task = Tasks::Task.new directory
  action = File.basename file
  name = task.name
  namespace name do
    task action do
      puts "Run task: #{name} action: #{action}"
      system file
    end
    task "#{action}/report" do
      task.report_read action
    end
    task "#{action}/raw" do
      task.report_raw action
    end
    task "#{action}/remove" do
      task.report_remove action
    end
    task "#{action}/success" do
      task.report_success action
    end
  end

  unless Rake.application.tasks.select { |t| t.name == name }.any?
    desc "#{name} task"
    task name do
      puts "Run full task: #{name}"
      Rake::Task["#{name}:pre"].invoke
      unless task.report_success action
        task.report_read action
        puts 'Pre-deployment test failed!'
        puts "Task #{name} deployment stopped!"
        exit
      end
      Rake::Task["#{name}:run"].invoke
      Rake::Task["#{name}:post"].invoke
    end
  end

end

# deploy preset of tasks
# argument start_task can set fist task to do
# /list can display tasks in preset
def deploy_preset(name, tasks)
  desc "Preset deploymnet: #{name}"
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
  next unless File.file?(path)
  next unless path.end_with?('/run') or path.end_with?('/pre') or path.end_with?('/post')
  make_task path
end

# show main tasks by default
task :default do
  tasks = Rake.application.tasks
  presents = tasks.select { |t| t.comment and t.name.start_with? 'preset/' }
  main_tasks = tasks.select { |t| t.comment and not t.name.start_with? 'preset/' }

  if presents.any?
    presents.each { |t| puts "#{t.name} (#{t.comment})" }
    puts '-' * 20 + "\n"
  end

  main_tasks.each do |t|
    puts "#{t.name} (#{t.comment})"
  end

end
