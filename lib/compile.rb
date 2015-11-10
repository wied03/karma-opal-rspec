require 'opal/rspec'

# or use Opal::RSpec::SprocketsEnvironment.new(spec_pattern='spec/opal/**/*_spec.{rb,opal}') to customize the pattern
sprockets_env = Opal::RSpec::SprocketsEnvironment.new
Opal.paths.each {|p| sprockets_env.append_path p }
sprockets_env.add_spec_paths_to_sprockets

COLLAPSE = %w{opal opal-rspec}
input_asset = ARGV[0]
if COLLAPSE.any? {|c| input_asset.include?(c)}
  puts sprockets_env[input_asset].to_s
else
  puts Opal.compile File.read(input_asset)
end
