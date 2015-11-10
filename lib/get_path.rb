require 'opal/rspec'

# or use Opal::RSpec::SprocketsEnvironment.new(spec_pattern='spec/opal/**/*_spec.{rb,opal}') to customize the pattern
sprockets_env = Opal::RSpec::SprocketsEnvironment.new
Opal.paths.each {|p| sprockets_env.append_path p }
sprockets_env.add_spec_paths_to_sprockets

puts sprockets_env[ARGV[0]].filename
