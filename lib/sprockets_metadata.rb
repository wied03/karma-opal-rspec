module SprocketsMetadata
  def self.get_dependency_graph(sprockets_env, files)
    files.map do |file_asset|
      asset = file_asset.is_a?(Sprockets::Asset) ? file_asset : sprockets_env.find_asset(file_asset)
      raw_deps = (asset.included || []).map { |a| sprockets_env.find_asset(a) }
                     .reject { |a| a.filename == asset.filename } # don't want ourself in here, sprockets includes that
      dependencies = get_dependency_graph sprockets_env, raw_deps
      {
          filename: asset.filename,
          logical_path: asset.logical_path,
          dependencies: dependencies
      }
    end
  end
end
