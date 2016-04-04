require 'rack'
require 'metadata_server'
require 'rails_detector'
require 'environment'
require 'opal_processor_patch'

module Karma
  module SprocketsServer
    class AssetServer
      include RailsDetector

      SOURCE_MAPS_PREFIX_PATH = '/__OPAL_SOURCE_MAPS__'

      def initialize(load_paths, default_path, mri_requires, roll_up_list, spec_patterns)
        if in_rails?
          require File.expand_path('config/environment')
        else
          Bundler.require
        end

        mri_requires.each { |file| require file }
        sprockets_env = Environment.new load_paths, default_path
        @app = create_app sprockets_env, roll_up_list, spec_patterns
      end

      def call(env)
        @app.call env
      end

      private

      def create_app(sprockets_env, roll_up_list, spec_patterns)
        Opal::Processor.source_map_enabled = true
        maps_prefix = SOURCE_MAPS_PREFIX_PATH
        maps_app = ::Opal::SourceMapServer.new(sprockets_env, maps_prefix)
        Opal::Sprockets::SourceMapHeaderPatch.inject!(maps_prefix)
        metadata_server = MetadataServer.new(sprockets_env, roll_up_list, spec_patterns)
        Rack::Builder.app do
          not_found = ->(_env) { [404, {}, []] }
          use Rack::Deflater
          use Rack::ShowExceptions
          map(maps_prefix) do
            use Rack::ConditionalGet
            use Rack::ETag
            run maps_app
          end
          map('/assets') { run sprockets_env }
          map('/metadata') { run metadata_server }
          run Rack::Static.new(not_found, root: nil, urls: ['/'])
        end
      end
    end
  end
end
