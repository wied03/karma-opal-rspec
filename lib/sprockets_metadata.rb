require 'uri'

module SprocketsMetadata
  def self.get_dependency_graph(sprockets_env, files, result=nil, current_dependency_chain=[])
    unless result
      result = {
          file_mapping: {},
          dependencies: {}
      }
    end
    file_mapping = result[:file_mapping]
    dependencies = result[:dependencies]

    files.each do |file_asset|
      asset = file_asset.is_a?(Sprockets::Asset) ? file_asset : sprockets_env.find_asset(file_asset)
      our_logical_path = asset.logical_path
      if current_dependency_chain.any? { |d| d.logical_path == our_logical_path }
        referring_paths = current_dependency_chain.map { |p| p.logical_path }
        raise "Circular dependency, one of #{referring_paths} refers to #{our_logical_path} and #{our_logical_path} refers to one of those files."
      end
      dependency_chain = current_dependency_chain.clone << asset
      our_dependency_results = dependencies[our_logical_path] ||= []
      dependency_assets = (asset.metadata[:included] || []).map { |dep|
        asset_uri = URI dep
        # Fetching with path to avoid the self/pipeline that sprockets puts on here
        sprockets_env.find_asset(asset_uri.path)
      }.reject { |a| a.filename == asset.filename }
      dependency_assets.each { |d| our_dependency_results << d.logical_path }
      get_dependency_graph sprockets_env, dependency_assets, result, dependency_chain
      file_mapping[our_logical_path] = asset.filename
    end
    result
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
