require 'rack'
require 'rake'
require 'json'
require 'metadata'
require 'opal_processor_patch'

module Karma
  module SprocketsServer
    class MetadataServer
      def initialize(sprockets_env, roll_up_list, spec_pattern)
        @sprockets_env = sprockets_env
        @specs = FileList[*spec_pattern].map { |file| File.absolute_path file }
        @roll_up_list = roll_up_list.any? ? roll_up_list : MetadataServer.default_roll_up_list
      end

      def call(*)
        core_graph = Metadata.get_dependency_graph @sprockets_env, %w{opal opal-rspec}
        core_deps = Metadata.get_metadata core_graph, @roll_up_list
        spec_graph = Metadata.get_dependency_graph @sprockets_env, @specs
        spec_deps = Metadata.get_metadata spec_graph, @roll_up_list
        all_deps = core_deps.merge spec_deps
        only_roll_up = all_deps.select { |_, meta| meta[:roll_up] }
        metadata = {
          load_paths: @sprockets_env.paths,
          roll_ups: only_roll_up
        }
        [200, {}, [metadata.to_json]]
      end

      class << self
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
