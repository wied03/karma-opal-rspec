require 'json'
require 'retryable'
require 'open-uri'

Given(/^the '(.*)' Karma config file$/) do |config_path|
  src = File.expand_path(File.join(File.dirname(__FILE__), '../../spec/integration/karma_configs', config_path))
  dest = File.expand_path(File.join(aruba.config.working_directory, 'karma.conf.js'))
  # FileUtils cp was doing weird stuff for some reason
  `cp -f #{src} #{dest}`
  src = File.expand_path(File.join(File.dirname(__FILE__), '../../spec/integration/entry_points', config_path))
  dest = File.expand_path(File.join(aruba.config.working_directory, 'entry_point.js'))
  `cp -f #{src} #{dest}`
end

When(/^I run the Karma test$/) do
  step 'I run `bundle exec ./node_modules/karma/bin/karma start --single-run --no-colors --log-level debug`'
end

class FileNotFoundError < StandardError
end

When(/^I run the Karma test and keep Karma running$/) do
  @karma_still_running = Process.spawn('./node_modules/karma/bin/karma start --no-colors --log-level debug',
                                       chdir: aruba.config.working_directory,
                                       pgroup: true)
  puts "Started Karma with new process group at PID #{@karma_still_running}"
  # karma/node start another process, so we want to be able to keep track of these
  @karma_still_running = Process.getpgid @karma_still_running
  Retryable.retryable(tries: 15,
                      sleep: 5,
                      on: FileNotFoundError) do
    raise FileNotFoundError unless File.exist?(File.join(aruba.config.working_directory, 'test_run.json'))
  end
end

Before do
  ENV['RAILS_ENV'] = nil # in case travis or local env has something here
end

After do
  if @karma_still_running
    group = -1 * @karma_still_running
    puts "Sending SIGINT to process group ID #{group}"
    Process.kill 'SIGINT', group
    Process.waitall
    ps_output = `ps ux`
    puts "Current processes after wait are #{ps_output}"
  end
end

Then(/^the test (passes|fails) with JSON results:$/) do |pass_fail, expected_json|
  filename = File.join(aruba.config.working_directory, 'test_run.json')
  expect(File).to exist(filename)
  actual = File.read(filename)
  expect(JSON.parse(actual)).to eq JSON.parse(expected_json)
  should_pass = pass_fail == 'passes'
  unless @karma_still_running
    if should_pass
      step 'the exit status should be 0'
    else
      step 'the exit status should not be 0'
    end
  end
end

Given(/^the (\S+) tests$/) do |spec_path|
  path = File.expand_path(File.join(File.dirname(__FILE__), '../../spec/integration', spec_path))
  dest = File.expand_path(File.join(aruba.config.working_directory, 'spec'))
  # FileUtils cp was doing weird stuff for some reason
  `cp -R #{path} #{dest}`
end

Given(/^I copy (\S+) to the working directory$/) do |path|
  path = File.expand_path(File.join(File.dirname(__FILE__), '../../', path))
  dest = File.expand_path(File.join(aruba.config.working_directory))
  # FileUtils cp was doing weird stuff for some reason
  `cp -R #{path} #{dest}`
end

Then(/^the test fails$/) do
  step 'the exit status should not be 0'
end
