require 'opal/rspec'
require 'json'

sprockets_env = Opal::RSpec::SprocketsEnvironment.new(spec_pattern=ARGV[0])
Opal.paths.each { |p| sprockets_env.append_path p }
sprockets_env.add_spec_paths_to_sprockets

pre_run_locator = Opal::RSpec::PreRackLocator.new sprockets_env.spec_pattern,
                                                  sprockets_env.spec_exclude_pattern,
                                                  sprockets_env.spec_files
locator = Opal::RSpec::PostRackLocator.new(pre_run_locator)

map_assets = lambda do |assets, include_deps=true|
  assets.map do |asset|
    main_asset = sprockets_env[asset]
    with_deps = [main_asset]
    with_deps += main_asset.included.map { |dep| sprockets_env[dep] } if include_deps
    with_deps.map do |dep_asset|
      {
          filename: dep_asset.filename,
          logical_path: dep_asset.logical_path
      }
    end
  end.flatten
end

GET_FULL_PATHS = %w{opal opal-rspec}
opal_rspec_paths = map_assets[GET_FULL_PATHS, include_deps=false]
with_dependencies = map_assets[locator.get_opal_spec_requires]

watch = lambda { |watch_it, arr| [*arr].map { |a| a.merge(watch: watch_it) } }

result = watch[false, opal_rspec_paths] + watch[true, with_dependencies]

puts result.to_json
