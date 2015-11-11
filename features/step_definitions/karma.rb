Given(/^the '(.*)' Karma config file$/) do |config_path|
  path = File.expand_path(File.join(File.dirname(__FILE__), '../..', config_path))
  dest = File.expand_path(File.join(aruba.config.working_directory, 'karma.conf.js'))
  # FileUtils cp was doing weird stuff for some reason
  `cp -f #{path} #{dest}`
end

When(/^I run the Karma test$/) do
  step 'I run `./node_modules/karma/bin/karma start --single-run --no-colors --log-level debug`'
end

Then(/^the results should be:$/) do |expected|
  filename = File.join(aruba.config.working_directory, 'test_run.json')
  expect(File).to exist(filename)
  actual = File.read(filename)
  expect(actual).to eq expected
end

Given(/^the (\S+) tests$/) do |spec_path|
  path = File.expand_path(File.join(File.dirname(__FILE__), '../../spec', spec_path))
  dest = File.expand_path(File.join(aruba.config.working_directory, 'spec'))
  FileUtils.cp_r path, dest
end
