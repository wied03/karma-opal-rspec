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
        # Rack Lint InputWrapper
        request_body = request.body.read
        request_info = JSON.parse request_body
        files = request_info['files']
        dependency_graph = SprocketsMetadata.get_dependency_graph @sprockets_env, files
        metadata = SprocketsMetadata.get_metadata dependency_graph, @roll_up_list
        [200, {}, [metadata.to_json]]
      end
    end
  end
end
