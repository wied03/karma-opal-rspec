require 'opal/rspec'
sprockets_env = Opal::RSpec::SprocketsEnvironment.new(spec_pattern='spec/unit/**/*_spec.rb')
run Opal::Server.new(sprockets: sprockets_env) { |s|
  s.main = 'opal/rspec/sprockets_runner'
  sprockets_env.add_spec_paths_to_sprockets
  s.append_path 'lib'
  s.debug = true
}
