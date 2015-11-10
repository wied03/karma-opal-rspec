require 'opal/rspec'
require 'json'

sprockets_env = Opal::RSpec::SprocketsEnvironment.new(spec_pattern=ARGV[0])
Opal.paths.each { |p| sprockets_env.append_path p }
sprockets_env.add_spec_paths_to_sprockets

GET_FULL_PATHS = %w{opal opal-rspec}

opal_rspec_paths = GET_FULL_PATHS.map { |p| sprockets_env[p].filename }
pre_run_locator = Opal::RSpec::PreRackLocator.new sprockets_env.spec_pattern,
                                                  sprockets_env.spec_exclude_pattern,
                                                  sprockets_env.spec_files
locator = Opal::RSpec::PostRackLocator.new(pre_run_locator)

with_dependencies = locator.get_opal_spec_requires.map do |r|
  compiler = Opal::Compiler.new(File.read(r))
  compiler.compile
  compiler.requires + [r]
end.flatten

test_paths = with_dependencies.map do |r|
  sprockets_env[r].filename
end

File.open ARGV[1], 'w' do |test_req_file|
  test_req_file << "Opal.require('opal/rspec');"
end

watch = lambda {|watch_it, arr| [*arr].map {|a| {file: a, watch: watch_it}}}

result = watch[false, opal_rspec_paths] + watch[false, ARGV[1]] + watch[true, test_paths]

puts result.to_json
