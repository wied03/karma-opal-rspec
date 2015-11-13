require 'cucumber/rake/task'
require 'opal/rspec/rake_task'

desc 'Runs Cucumber/integration tests'
Cucumber::Rake::Task.new(:cucumber) do |t|
  t.cucumber_opts = 'features --format pretty'
end

Opal::RSpec::RakeTask.new(:spec) do |server, task|
  task.pattern = 'spec/unit/**/*_spec.rb'
  server.append_path 'lib'
end

task :js_hint do
  sh 'node_modules/jshint/bin/jshint lib/*.js'
end

task :default => [:js_hint, :spec, :cucumber]
