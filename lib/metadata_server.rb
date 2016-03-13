require 'rack'
require 'json'
require 'opal_processor_patch'
require 'sprockets_metadata'

module Karma
  module Opal
    class MetadataServer
      def initialize(sprockets_env, roll_up_list)
        @sprockets_env = sprockets_env
        @roll_up_list = roll_up_list.any? ? roll_up_list : SprocketsMetadata.default_roll_up_list
      end

      def call(env)
        request = Rack::Request.new env
        request_info = JSON.parse request.body.string
        files = request_info['files']
        watch = request_info['watch']
        exclude_self = request_info['exclude_self']
        dependency_graph = SprocketsMetadata.get_dependency_graph @sprockets_env, files
        metadata = SprocketsMetadata.get_metadata dependency_graph, @roll_up_list, watch
        # Karma will handle the tests themselves, we're just concerned about dependencies
        metadata = metadata.reject { |key, _| files.include?(key) } if exclude_self
        [200, {}, metadata.to_json]
      end
    end
  end
end
