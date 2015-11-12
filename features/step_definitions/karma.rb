require 'json'

Given(/^the '(.*)' Karma config file$/) do |config_path|
  src = File.expand_path(File.join(File.dirname(__FILE__), '../../spec/karma_configs', config_path))
  dest = File.expand_path(File.join(aruba.config.working_directory, 'karma.conf.js'))
  # FileUtils cp was doing weird stuff for some reason
  `cp -f #{src} #{dest}`
end

When(/^I run the Karma test$/) do
  step 'I run `./node_modules/karma/bin/karma start --single-run --no-colors --log-level debug`'
end

Then(/^the test (passes|fails) with JSON results:$/) do |pass_fail, expected_json|
  filename = File.join(aruba.config.working_directory, 'test_run.json')
  expect(File).to exist(filename)
  actual = File.read(filename)
  expect(JSON.parse(actual)).to eq JSON.parse(expected_json)
  should_pass = pass_fail == 'passes'
  if should_pass
    step 'the exit status should be 0'
  else
    step 'the exit status should not be 0'
  end
end

Given(/^the (\S+) tests$/) do |spec_path|
  path = File.expand_path(File.join(File.dirname(__FILE__), '../../spec', spec_path))
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
