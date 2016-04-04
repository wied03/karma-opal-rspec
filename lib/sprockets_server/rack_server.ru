require 'asset_server'

patterns = ENV['PATTERN'].split(',')
load_paths = ENV['OPAL_LOAD_PATH'].split(',')
# undefined as sent as empty string across env from JS
load_paths << 'spec' if load_paths.empty?
mri_requires = ENV['MRI_REQUIRES'].split(',')
roll_up_list = (ENV['OPAL_ROLL_UP'] || '').split(',')
roll_up_list = roll_up_list.map do |r|
  # convert JS supplied regexps back into Ruby regexps if necessary
  regexp_match = /^\/(.*)\/$/.match(r)
  regexp_match ? Regexp.new(regexp_match.captures[0]) : r
end

run Karma::SprocketsServer::AssetServer.new(load_paths, mri_requires, roll_up_list, patterns)
