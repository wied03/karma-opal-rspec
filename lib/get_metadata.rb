require 'opal/rspec'
require 'json'

sprockets_env = Opal::RSpec::SprocketsEnvironment.new(spec_pattern=ARGV[0])
Opal.paths.each { |p| sprockets_env.append_path p }
sprockets_env.add_spec_paths_to_sprockets
sprockets_env.append_path File.dirname(__FILE__)

pre_run_locator = Opal::RSpec::PreRackLocator.new sprockets_env.spec_pattern,
                                                  sprockets_env.spec_exclude_pattern,
                                                  sprockets_env.spec_files
locator = Opal::RSpec::PostRackLocator.new(pre_run_locator)

map_assets = lambda do |assets, watch, include_deps=true|
  assets.inject({}) do |result, asset|
    main_asset = sprockets_env[asset]
    with_deps = [main_asset]
    with_deps += main_asset.included.map { |dep| sprockets_env[dep] } if include_deps
    as_array = with_deps.map do |dep_asset|
      [
          dep_asset.filename,
          {
              logical_path: dep_asset.logical_path,
              watch: watch
          }
      ]
    end
    result.merge! Hash[as_array]
  end
end

GET_FULL_PATHS = %w{opal opal-rspec}
INTERNAL_PATHS = %w{karma_formatter}
opal_rspec_paths = map_assets[GET_FULL_PATHS, watch=false, include_deps=false]
internal_paths = map_assets[INTERNAL_PATHS, watch=false, include_deps=false]
with_dependencies = map_assets[locator.get_opal_spec_requires, watch=true]

result = opal_rspec_paths.merge(internal_paths).merge(with_dependencies)

puts result.to_json
