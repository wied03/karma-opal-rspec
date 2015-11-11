Given(/^the '(.*)' Karma config file$/) do |config_path|
  path = File.join(File.dirname(__FILE__), '../..', config_path)
  FileUtils.cp path, File.join(aruba.config.working_directory,'karma.conf.js')
end

When(/^I run the Karma test$/) do
  step 'I run `./node_modules/karma/bin/karma start --single-run --no-colors --log-level debug`'
end

Then(/^the results should be:$/) do |expected|
  filename = 'test_run.json'
  expect(File).to exist(filename)
  actual = File.read(filename)
  expect(actual).to eq expected
end
