require 'rack'
require 'json'
require 'opal_processor_patch'

module Karma
  module SprocketsServer
    class MetadataServer
      def initialize(sprockets_env, roll_up_list)
        @sprockets_env = sprockets_env
        @roll_up_list = roll_up_list.any? ? roll_up_list : MetadataServer.default_roll_up_list
      end

      def call(env)
        metadata = {
          load_paths: @sprockets_env.paths
        }
        [200, {}, [metadata.to_json]]
      end

      class << self
        private

        def default_roll_up_list
          # use find all to catch pre-release
          opal_spec = Gem::Specification.find_all_by_name('opal').first
          gems_dir = File.expand_path('..', opal_spec.gem_dir)
          [Regexp.new(Regexp.escape(gems_dir))]
        end
      end
    end
  end
end
