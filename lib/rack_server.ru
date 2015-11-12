require 'opal/rspec'

patterns = ENV['PATTERN'].split(',')

# Karma explodes the paths
relative_patterns = patterns.map do |p|
  Pathname.new(p).relative_path_from(Pathname.new(Dir.pwd)).to_s
end

puts "Launching Rack server with pattern #{relative_patterns}"
sprockets_env = Opal::RSpec::SprocketsEnvironment.new(spec_pattern=relative_patterns)
run Opal::Server.new(sprockets: sprockets_env) { |s|
  s.main = 'opal/rspec/sprockets_runner'
  sprockets_env.add_spec_paths_to_sprockets
  # formatter, etc.
  sprockets_env.append_path File.dirname(__FILE__)
  s.debug = true
  s.source_map = true
}
