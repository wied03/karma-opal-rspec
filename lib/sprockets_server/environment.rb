require 'rails_detector'
require 'sprockets'

module Karma
  module SprocketsServer
    class Environment < Sprockets::Environment
      include RailsDetector

      def initialize(load_paths)
        super()

        Opal.paths.each { |path| append_path(path) }
        logger.level ||= Logger::DEBUG
        # dependencies like opal and opal-rspec won't change much from 1 Karma run to the next, so using a persistent cache store
        self.cache = Sprockets::Cache::FileStore.new('./tmp/cache/karma_opal_rspec')
        # reporter path
        append_path File.expand_path(File.join(File.dirname(__FILE__), '..', 'opal_rspec'))
        load_paths.each { |path| append_path path }
        Rails.application.assets.paths.each { |path| append_path path } if in_rails?
      end
    end
  end
end
