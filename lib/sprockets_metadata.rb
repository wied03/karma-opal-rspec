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
      dependency_assets.each { |d| our_dependency_results << d.logical_path unless our_dependency_results.include?(d.logical_path) }
      new_deps = dependency_assets.reject { |d| dependencies.include?(d.logical_path) }
      get_dependency_graph sprockets_env, new_deps, result, dependency_chain
      file_mapping[our_logical_path] = asset.filename
    end
    result
  end

  def self.default_roll_up_list
    # use find all to catch pre-release
    opal_spec = Gem::Specification.find_all_by_name('opal').first
    gems_dir = File.expand_path('..', opal_spec.gem_dir)
    [Regexp.new(Regexp.escape(gems_dir))]
  end

  def self.get_metadata(dependency_graph, roll_up_list, watch)
    dep_hash = {}
    file_mapping = dependency_graph[:file_mapping]
    file_mapping.each do |logical_path, filename|
      roll_up = roll_up_list.any? do |r|
        if r.is_a?(Regexp)
          r.match filename
        else
          base_asset_name = File.basename(filename)
          base_asset_name == r
        end
      end
      if roll_up
        dependency_graph[:dependencies][logical_path].each do |dep|
          dep_hash.delete file_mapping[dep]
        end
      else
      end
      dep_hash[filename] = {
          logical_path: logical_path,
          watch: watch,
          roll_up: roll_up
      }
    end
    dep_hash
  end
end
