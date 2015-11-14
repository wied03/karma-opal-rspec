require 'uri'

module SprocketsMetadata
  def self.get_dependency_graph(sprockets_env, files)
    file_mapping = {}
    dependencies = {}
    result = {
        file_mapping: file_mapping,
        dependencies: dependencies
    }
    files.each do |file_asset|
      asset = file_asset.is_a?(Sprockets::Asset) ? file_asset : sprockets_env.find_asset(file_asset)
      our_logical_path = asset.logical_path
      puts "asset #{our_logical_path}"
      our_dependency_results = dependencies[our_logical_path] ||= []
      dependency_assets = (asset.metadata[:included] || []).map { |dep|
        asset_uri = URI dep
        # Fetching with path to avoid the self/pipeline that sprockets puts on here
        sprockets_env.find_asset(asset_uri.path)
      }.reject { |a| a.filename == asset.filename }
      dependency_assets.each do |dep|
        puts "handling dependency #{dep.logical_path}"
        next if file_mapping.include? dep.logical_path
        our_dependency_results << dep.logical_path
        results = get_dependency_graph sprockets_env, [dep]
        file_mapping.merge! results[:file_mapping]
        dependencies.merge! results[:dependencies]
      end
      file_mapping[our_logical_path] = asset.filename
    end
    result

    # files.map do |file_asset|
    #   asset = file_asset.is_a?(Sprockets::Asset) ? file_asset : sprockets_env.find_asset(file_asset)
    #   raw_deps = (asset.metadata[:included] || []).map { |dep|
    #     asset_uri = URI dep
    #     # Fetching with path to avoid the self/pipeline that sprockets puts on here
    #     sprockets_env.find_asset(asset_uri.path)
    #   }
    #                  .reject { |a| a.filename == asset.filename } # don't want ourself in here, sprockets includes that
    #   if already_processed.include? file_asset
    #     our_path = asset.logical_path
    #     referring_paths = already_processed.map { |p| p.is_a?(Sprockets::Asset) ? p.logical_path : p.to_s }
    #     raise "Circular dependency, one of #{referring_paths} refers to #{our_path} and #{our_path} refers to one of those files."
    #   end
    #   dependencies = get_dependency_graph sprockets_env, raw_deps, (already_processed + [file_asset])
    #   Asset.new(asset.filename,
    #             asset.logical_path,
    #             dependencies)
    # end
  end

  def self.get_metadata(dependency_graph, roll_up_list, watch, already_rolled_up={})
    dep_hash = {}
    dependency_graph.each do |dep|
      next if already_rolled_up.include? dep
      base_asset_name = File.basename(dep.filename)
      roll_up = roll_up_list.include? base_asset_name
      if roll_up
        dep.dependencies.each do |d|
          already_rolled_up[d] = true
          # If this dependency was included separately earlier in the run, we'll remove it to reduce duplication
          dep_hash.delete d.filename
        end
      else
        new_dependencies = dep.dependencies - already_rolled_up.keys
        dep_hash.merge!(get_metadata(new_dependencies, roll_up_list, watch, already_rolled_up))
      end
      dep_hash[dep.filename] = {
          logical_path: dep.logical_path,
          watch: watch,
          roll_up: roll_up
      }
    end
    dep_hash
  end
end
