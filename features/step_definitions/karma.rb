require 'json'
require 'retryable'
require 'open-uri'

Given(/^the '(.*)' Karma config file$/) do |config_path|
  src = File.expand_path(File.join(File.dirname(__FILE__), '../../spec/integration/karma_configs', config_path))
  dest = File.expand_path(File.join(aruba.config.working_directory, 'karma.conf.js'))
  # FileUtils cp was doing weird stuff for some reason
  `cp -f #{src} #{dest}`
end

When(/^I run the Karma test$/) do
  step 'I run `./node_modules/karma/bin/karma start --single-run --no-colors --log-level debug`'
end

class FileNotFoundError < StandardError
end

When(/^I run the Karma test and keep Karma running$/) do
  @karma_still_running = Process.spawn('./node_modules/karma/bin/karma start --no-colors',
                                       chdir: aruba.config.working_directory,
                                       pgroup: true)
  puts "Started Karma with new process group at PID #{@karma_still_running}"
  # karma/node start another process, so we want to be able to keep track of these
  @karma_still_running = Process.getpgid @karma_still_running
  puts "Started Karma with new process group ID #{@karma_still_running}"
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

BASE_URL = 'http://localhost:9876'

And(/^the following source maps exist:$/) do |expected_maps|
  expected_maps.hashes.each do |expected|
    expected_source_map_path = expected[:'Map URL']
    js_url = URI.join(BASE_URL, expected[:File])
    open(js_url) do |js_file|
      expect(js_file.read).to include "//# sourceMappingURL=#{expected_source_map_path}"
    end
    source_map_full_path = File.expand_path("../#{expected_source_map_path}", js_url.path)
    source_map_contents = nil
    open(URI.join(BASE_URL, source_map_full_path)) do |source_map|
      source_map_contents = source_map.read
    end
    source_map_contents = JSON.parse source_map_contents
    expect(source_map_contents['file']).to eq expected[:'Original File']
    expected_sources = expected[:Sources].split ','
    expect(source_map_contents['sources']).to eq expected_sources
    expected_sources.each do |source|
      open(URI.join(BASE_URL, source)) do |original_source|
        expect(original_source.read).to_not be_empty
      end
    end
  end
end

And(/^the following files do not have source maps:$/) do |table|
  # table is a table.hashes.keys # => [:File]
  table.hashes.each do |file|
    open(URI.join(BASE_URL, file[:File])) do |js_file|
      expect(js_file.read).to_not include 'sourceMappingURL'
    end
  end
end

And(/^the following files have unresolvable source maps:$/) do |table|
  # table is a table.hashes.keys # => [:File]
  table.hashes.each do |file|
    source_map_path = nil
    js_url = URI.join(BASE_URL, file[:File])
    open(js_url) do |js_file|
      match = /\/\/# sourceMappingURL=(.*)/.match(js_file.read)
      expect(match).to_not be_nil
      source_map_path = match.captures[0]
    end
    source_map_full_path = File.expand_path("../#{source_map_path}", js_url.path)
    expect { open(URI.join(BASE_URL, source_map_full_path)) { |f|} }.to raise_exception OpenURI::HTTPError, '404 Not Found'
  end
end
