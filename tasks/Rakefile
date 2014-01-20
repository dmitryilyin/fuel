import 'components.rake'

def deploy(name, stages)
  desc "Deploy #{name}"
  task "deploy/#{name}", :start_stage do |t, args|
    fail "No stages given for task #{t}!" unless stages.respond_to?(:each) && stages.any?
    start_from = stages.index(args.start_stage) if args.start_stage
    if start_from && start_from > 0
      puts "Starting from stage #{args.start_stage}"
      stages = stages.drop(start_from || 0)
    end
    stages.each do |stage|
      Rake::Task["#{stage}:apply"].invoke
      Rake::Task["#{stage}:test"].invoke
    end
  end
  task "deploy/#{name}/list" do
    stages.each_with_index do |stage, num|
      puts "#{num + 1} #{stage}"
    end
  end
end

task :default do
  system("rake -sT")
end

################################

sanity_stages = [
  'common/supported',
  'common/role',
]

network_stages = [
  'common/network',
  'common/firewall',
]
  
common_stages = sanity_stages + [
  'common/repos',
  'common/basic',
  'common/profile',
  'common/trace',
]

controller_stages = common_stages + network_stages + [
  'controller/controller',
  'controller/auth_file',
  'controller/cirros',
  'controller/rsyslog',
  'controller/tinyproxy',
  'controller/floating',
]

compute_stages = common_stages + [
  'compute/compute',
  'compute/rsyslog',
]

################################

deploy :common, common_stages
deploy :controller, controller_stages
