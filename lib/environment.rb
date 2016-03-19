require 'rails_detector'

module Karma
  module Opal
    class Environment < Sprockets::Environment
      include RailsDetector

      def initialize(load_paths, default_path)
        super()

        ::Opal.paths.each { |path| append_path(path) }
        logger.level ||= Logger::DEBUG
        # dependencies like opal and opal-rspec won't change much from 1 Karma run to the next, so using a persistent cache store
        self.cache = Sprockets::Cache::FileStore.new('./tmp/cache/karma_opal_rspec')
        append_path default_path
        # formatter, etc.
        append_path File.dirname(__FILE__)
        load_paths.each { |path| append_path path }
        Rails.application.assets.paths.each { |path| append_path path } if in_rails?
      end
    end
  end
end
