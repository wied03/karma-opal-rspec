require 'opal/rspec'

# We load these from Karma
CORE = %w{opal.rb opal-rspec.rb}
input_asset = ARGV[0]
if CORE.any? { |c| File.basename(input_asset) == c }
  sprockets_env = Opal::RSpec::SprocketsEnvironment.new
  Opal.paths.each { |p| sprockets_env.append_path p }
  sprockets_env.add_spec_paths_to_sprockets
  sprockets_env.append_path File.dirname(__FILE__)
  puts sprockets_env[input_asset].to_s
else
  compiler = Opal::Compiler.new(File.read(input_asset))
  puts compiler.compile
end
