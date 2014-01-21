require 'find'
Rake::TaskManager.record_task_metadata = true

TASKS_DIR = File.dirname(File.expand_path(__FILE__))
Dir.chdir(TASKS_DIR) || exit(1)

Find.find('.') do |path|
  next unless File.file?(path)
  next unless path.end_with?('/run') or path.end_with?('/pre') or path.end_with?('/post')
  path.sub!('./','')
  task_name = File.dirname(path)
  task_name.sub!('/',':')

  if path.end_with?('/run')
    namespace task_name do
      task :run do
        puts "Run task process #{task_name}"
        system path
      end
    end
  end
  
  if path.end_with?('/pre')
    namespace task_name do
      task :pre do
        puts "Run pre-deploy test #{task_name}"
        system path
      end
    end
  end
  
  if path.end_with?('/post')
    namespace task_name do
      task :post do
        puts "Run post-deploy test #{task_name}"
        system path
      end
    end
  end
  
  if path.end_with?('/run')
    desc "#{task_name} task"
    task task_name do
      puts "Run full task #{task_name}"
      Rake::Task["#{task_name}:pre"].invoke
      Rake::Task["#{task_name}:run"].invoke
      Rake::Task["#{task_name}:post"].invoke
    end
  end

end
