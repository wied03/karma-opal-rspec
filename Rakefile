require 'cucumber/rake/task'

desc 'Runs Cucumber/integration tests'
Cucumber::Rake::Task.new(:cucumber) do |t|
  t.cucumber_opts = 'features --format pretty'
end

task :js_hint do
  sh 'node_modules/jshint/bin/jshint lib/*.js'
end

task :default => [:js_hint, :cucumber]
