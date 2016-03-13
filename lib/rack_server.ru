require 'opal/rspec'
require 'opal_processor_patch'
require 'karma_rack'

load_paths = ENV['OPAL_LOAD_PATH'].split(',')
mri_requires = ENV['MRI_REQUIRES'].split(',')
in_rails = (rails_env = ENV['RAILS_ENV']) && !rails_env.empty?
default_path = ENV['OPAL_DEFAULT_PATH']
# undefined as sent as empty string across env from JS
default_path = 'spec' if default_path.empty?

if in_rails
  require File.expand_path('config/environment')
else
  Bundler.require
end

mri_requires.each { |file| require file }

# TODO: Remove the upfront metadata check. Instead, spin up a small web server
# that will respond to 1 asset at a time and reply with the the dependencies/metadata for that asset only
# then use the emitter dependency (injected by Karma into the preprocessor) to add files if need be
# TODO: Convert the application to a simple Rack app (or sinatra app)
# This will mean no opal rspec sprockets environment, instead it will be a regular sprockets environment
# and the rack side will not know about test patterns anymore, just default path, any additional opal
# load paths, and the roll up list

run KarmaRack.new(load_paths, in_rails, default_path)
