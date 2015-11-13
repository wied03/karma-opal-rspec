module SprocketsMetadata
  Asset = Struct.new(:filename, :logical_path, :dependencies)

  def self.get_dependency_graph(sprockets_env, files)
    files.map do |file_asset|
      asset = file_asset.is_a?(Sprockets::Asset) ? file_asset : sprockets_env.find_asset(file_asset)
      raw_deps = (asset.metadata[:included] || []).map { |a| sprockets_env.find_asset(a) }
                     .reject { |a| a.filename == asset.filename } # don't want ourself in here, sprockets includes that
      dependencies = get_dependency_graph sprockets_env, raw_deps
      Asset.new(asset.filename,
                asset.logical_path,
                dependencies)
    end
  end

  def self.get_metadata(dependency_graph, roll_up_list, watch)
    dep_hash = {}
    dependency_graph.each do |dep|
      base_asset_name = File.basename(dep.filename)
      roll_up = roll_up_list.include? base_asset_name
      dep_hash.merge!(get_metadata(dep.dependencies, roll_up_list, watch)) unless roll_up
      dep_hash[dep.filename] = {
          logical_path: dep.logical_path,
          watch: watch,
          roll_up: roll_up
      }
    end
    dep_hash
  end
end
