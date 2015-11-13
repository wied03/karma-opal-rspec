module SprocketsMetadata
  Asset = Struct.new(:filename, :logical_path, :dependencies)

  def self.get_dependency_graph(sprockets_env, files)
    files.map do |file_asset|
      asset = file_asset.is_a?(Sprockets::Asset) ? file_asset : sprockets_env.find_asset(file_asset)
      raw_deps = (asset.included || []).map { |a| sprockets_env.find_asset(a) }
                     .reject { |a| a.filename == asset.filename } # don't want ourself in here, sprockets includes that
      dependencies = get_dependency_graph sprockets_env, raw_deps
      Asset.new(asset.filename,
                asset.logical_path,
                dependencies)
    end
  end

  def self.get_metadata(dependency_graph, roll_up_list, watch_list)
    as_array = dependency_graph.map do |dep|
      [dep.filename, {
          logical_path: dep.logical_path,
          watch: false
      }]
    end
    Hash[as_array]
  end
end
