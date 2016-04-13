require 'cucumber/rake/task'
require 'opal/rspec/rake_task'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'reek/rake/task'

desc 'Runs Cucumber/integration tests'
Cucumber::Rake::Task.new(:cucumber) do |t|
  t.cucumber_opts = 'features --format pretty'
end

desc 'JS Hint on JScode'
task :js_hint do
  sh 'node_modules/jshint/bin/jshint lib/*.js'
end

desc 'ESLint on JS code'
task :es_lint do
  sh 'node node_modules/eslint/bin/eslint.js lib'
end

desc 'Runs Rubocop'
RuboCop::RakeTask.new do |task|
  task.options = %w(-D -S)
end

Reek::Rake::Task.new do |task|
  # rake task overrides all config.reek exclusions, which is annoying and it won't let us set a FileList directly
  files = FileList['**/*.rb']
          .exclude('node_modules/**/*')
          .exclude('vendor/**/*') # Travis stuff
  task.instance_variable_set :@source_files, files
end

task default: [:js_hint, :es_lint, :rubocop, :reek, :cucumber]
