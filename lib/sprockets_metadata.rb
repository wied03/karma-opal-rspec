module SprocketsMetadata
  def self.get_dependency_graph(sprockets_env, files)
    files.map do |file|
      asset = sprockets_env.find_asset(file)
      {
          filename: asset.filename,
          logical_path: asset.logical_path,
          dependencies: []
      }
    end
  end
end
