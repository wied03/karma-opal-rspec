require 'opal/rspec'

# TODO: Merge karma spec path config and this one
# or use Opal::RSpec::SprocketsEnvironment.new(spec_pattern='spec/opal/**/*_spec.{rb,opal}') to customize the pattern
sprockets_env = Opal::RSpec::SprocketsEnvironment.new
Opal.paths.each {|p| sprockets_env.append_path p }
sprockets_env.add_spec_paths_to_sprockets

# We already have this covered and cached, so don't worry about it
STUB_IF_NOT_CORE = %w{opal opal-rspec opal/rspec opal/mini opal/base}

# We load these from Karma
CORE = %w{opal opal-rspec}
input_asset = ARGV[0]
unless CORE.any? {|c| input_asset.include?(c)}
  STUB_IF_NOT_CORE.each { |s| Opal::Processor.stub_file s }
end

puts sprockets_env[input_asset].to_s
