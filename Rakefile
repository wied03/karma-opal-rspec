require 'cucumber/rake/task'
require 'opal/rspec/rake_task'
require 'rspec/core/rake_task'

desc 'Runs Cucumber/integration tests'
Cucumber::Rake::Task.new(:cucumber) do |t|
  t.cucumber_opts = 'features --format pretty'
end

Opal::RSpec::RakeTask.new(:spec_opal) do |server, task|
  task.pattern = 'spec/unit/opal/**/*_spec.rb'
  task.default_path = 'spec/unit/opal'
  server.append_path 'lib'
  task.runner = :node
end

RSpec::Core::RakeTask.new(:spec_mri) do |task|
  task.pattern = 'spec/unit/mri/**/*_spec.rb'
end

task :spec => [:spec_mri, :spec_opal]

task :js_hint do
  sh 'node_modules/jshint/bin/jshint lib/*.js'
end

task :es_lint do
  sh 'node_modules/eslint/bin/eslint.js lib'
end

task :default => [:js_hint, :es_lint, :spec, :cucumber]
