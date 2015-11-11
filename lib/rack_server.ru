require 'opal/rspec'

pattern = ENV['PATTERN']
pattern = Pathname.new(pattern).relative_path_from(Pathname.new(Dir.pwd)).to_s
puts "Launching Rack server with pattern #{pattern}"
# or use Opal::RSpec::SprocketsEnvironment.new(spec_pattern='spec/opal/**/*_spec.{rb,opal}') to customize the pattern
sprockets_env = Opal::RSpec::SprocketsEnvironment.new(spec_pattern=pattern)
run Opal::Server.new(sprockets: sprockets_env) { |s|
  s.main = 'opal/rspec/sprockets_runner'
  sprockets_env.add_spec_paths_to_sprockets
  # formatter, etc.
  sprockets_env.append_path File.dirname(__FILE__)
  s.debug = true
  s.source_map = true
}
