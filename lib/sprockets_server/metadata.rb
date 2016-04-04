require 'uri'

module Karma
  module SprocketsServer
    module Metadata
      def self.get_dependency_graph(sprockets_env, files, result = nil, current_dependency_chain = [])
        result ||= {
          file_mapping: {},
          dependencies: Hash.new([]),
          errors: {}
        }
        file_mapping = result[:file_mapping]
        dependencies = result[:dependencies]

        files.each do |file_asset|
          asset = file_asset.is_a?(::Sprockets::Asset) ? file_asset : sprockets_env.find_asset(file_asset)
          raise "Unable to find asset #{file_asset}" unless asset
          our_logical_path = asset.logical_path
          dependency_assets = get_dependent_assets(asset, current_dependency_chain, sprockets_env)
          dependent_logical_paths = dependency_assets.map(&:logical_path)
          dependencies[our_logical_path] = (dependencies[our_logical_path] + dependent_logical_paths).uniq
          new_dependencies = dependency_assets.reject { |dependency| dependencies.include?(dependency.logical_path) }
          dependency_chain = current_dependency_chain.clone << asset
          get_dependency_graph sprockets_env, new_dependencies, result, dependency_chain
          file_mapping[our_logical_path] = asset.filename
        end
        result
      end

      def self.get_dependent_assets(asset, original_dependency_chain, sprockets_env)
        our_logical_path = asset.logical_path
        if original_dependency_chain.any? { |dependency| dependency.logical_path == our_logical_path }
          referring_paths = original_dependency_chain.map(&:logical_path)
          raise "Circular dependency, one of #{referring_paths} refers to #{our_logical_path} and #{our_logical_path} refers to one of those files."
        end
        all_assets = (asset.metadata[:included] || []).map do |dep|
          asset_uri = URI dep
          # Fetching with path to avoid the self/pipeline that sprockets puts on here
          sprockets_env.find_asset(asset_uri.path)
        end
        # Don't want to include ourselves
        all_assets.reject { |other_asset| other_asset.filename == asset.filename }
      end

      def self.get_metadata(dependency_graph, roll_up_list)
        dep_hash = {}
        file_mapping = dependency_graph[:file_mapping]
        file_mapping.each do |logical_path, filename|
          roll_up = roll_up_list.any? do |roll_up_item|
            if roll_up_item.is_a?(Regexp)
              roll_up_item.match filename
            else
              base_asset_name = File.basename(filename)
              base_asset_name == roll_up_item
            end
          end
          if roll_up
            dependency_graph[:dependencies][logical_path].each do |dep|
              dep_hash.delete file_mapping[dep]
            end
          end
          dep_hash[filename] = {
            logical_path: logical_path,
            roll_up: roll_up
          }
        end
        dependency_graph[:errors].each do |error_filename, error_message|
          dep_hash[error_filename] = {
            error: error_message
          }
        end
        dep_hash
      end
    end
  end
end
