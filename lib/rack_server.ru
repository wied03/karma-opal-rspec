require 'opal/rspec'

patterns = ENV['PATTERN'].split(',')
load_paths = ENV['OPAL_LOAD_PATH'].split(',')
in_rails = (rails_env = ENV['RAILS_ENV']) && !rails_env.empty?
default_path = ENV['OPAL_DEFAULT_PATH']
# undefined as sent as empty string across env from JS
default_path = nil if default_path.empty?

if in_rails
  require File.expand_path('config/environment')
end

# Karma explodes the paths
relative_patterns = patterns.map do |p|
  Pathname.new(p).relative_path_from(Pathname.new(Dir.pwd)).to_s
end

puts "Launching Rack server with pattern #{relative_patterns}"
sprockets_env = Opal::RSpec::SprocketsEnvironment.new(spec_pattern=relative_patterns,
                                                      spec_exclude_pattern=nil,
                                                      spec_files=nil,
                                                      default_path=default_path)
# dependencies like opal and opal-rspec won't change much from 1 Karma run to the next, so using a persistent cache store
sprockets_env.cache = Sprockets::Cache::FileStore.new('./tmp/cache/karma_opal_rspec')
run Opal::Server.new(sprockets: sprockets_env) { |s|
  s.main = 'opal/rspec/sprockets_runner'
  sprockets_env.add_spec_paths_to_sprockets
  # formatter, etc.
  sprockets_env.append_path File.dirname(__FILE__)
  load_paths.each { |p| sprockets_env.append_path p }
  Rails.application.assets.paths.each { |p| s.append_path p } if in_rails
  s.debug = true
  s.source_map = true
}
