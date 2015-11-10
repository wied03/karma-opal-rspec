require 'opal/rspec'
require 'json'

sprockets_env = Opal::RSpec::SprocketsEnvironment.new(spec_pattern=ARGV[0])
Opal.paths.each {|p| sprockets_env.append_path p }
sprockets_env.add_spec_paths_to_sprockets

GET_FULL_PATHS = %w{opal-rspec opal}

full_paths = GET_FULL_PATHS.map {|p| sprockets_env[p].filename}
pre_run_locator = Opal::RSpec::PreRackLocator.new sprockets_env.spec_pattern,
                                                  sprockets_env.spec_exclude_pattern, 
                                                  sprockets_env.spec_files
locator = Opal::RSpec::PostRackLocator.new(pre_run_locator)
test_requires = locator.get_opal_spec_requires.map do |r|
  logical = sprockets_env[r].logical_path
  logical.sub File.extname(logical), ''
end

result = {
  framework_paths: full_paths,
}

File.open ARGV[1], 'w' do |test_req_file|
  test_req_file << "Opal.require('opal/rspec');"
  test_requires.each do |req|
    test_req_file << "Opal.require('#{req}');"
  end
end

puts result.to_json
