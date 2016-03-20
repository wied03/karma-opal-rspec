require 'rack'
require 'json'
require 'opal_processor_patch'
require 'metadata'

module Karma
  module SprocketsServer
    class MetadataServer
      def initialize(sprockets_env, roll_up_list)
        @sprockets_env = sprockets_env
        @roll_up_list = roll_up_list.any? ? roll_up_list : Metadata.default_roll_up_list
      end

      def call(env)
        request = Rack::Request.new env
        # Rack Lint InputWrapper
        request_body = request.body.read
        request_info = JSON.parse request_body
        files = request_info['files']
        dependency_graph = Metadata.get_dependency_graph @sprockets_env, files
        metadata = Metadata.get_metadata dependency_graph, @roll_up_list
        [200, {}, [metadata.to_json]]
      end
    end
  end
end
