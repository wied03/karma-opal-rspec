require 'asset_server'

load_paths = ENV['OPAL_LOAD_PATH'].split(',')
mri_requires = ENV['MRI_REQUIRES'].split(',')
default_path = ENV['OPAL_DEFAULT_PATH']
# undefined as sent as empty string across env from JS
default_path = 'spec' if default_path.empty?
roll_up_list = (ENV['OPAL_ROLL_UP'] || '').split(',')
roll_up_list = roll_up_list.map do |r|
  # convert JS supplied regexps back into Ruby regexps if necessary
  regexp_match = /^\/(.*)\/$/.match(r)
  regexp_match ? Regexp.new(regexp_match.captures[0]) : r
end

run Karma::SprocketsServer::AssetServer.new(load_paths, default_path, mri_requires, roll_up_list)
