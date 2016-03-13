class KarmaRack
  SOURCE_MAPS_PREFIX_PATH = '/__OPAL_SOURCE_MAPS__'

  def initialize(load_paths, in_rails, default_path)
    @sprockets_env = sprockets_env in_rails, default_path, load_paths
    @app = create_app
  end

  def sprockets_env(in_rails, default_path, load_paths)
    sprockets_env = Sprockets::Environment.new
    sprockets_env.logger.level ||= Logger::DEBUG
    # dependencies like opal and opal-rspec won't change much from 1 Karma run to the next, so using a persistent cache store
    sprockets_env.cache = Sprockets::Cache::FileStore.new('./tmp/cache/karma_opal_rspec')
    sprockets_env.append_path default_path
    # formatter, etc.
    sprockets_env.append_path File.dirname(__FILE__)
    load_paths.each { |p| sprockets_env.append_path p }
    Rails.application.assets.paths.each { |p| sprockets_env.append_path p } if in_rails
    sprockets_env
  end

  def create_app
    Opal::Processor.source_map_enabled = true
    maps_prefix = SOURCE_MAPS_PREFIX_PATH
    maps_app = SourceMapServer.new(@sprockets_env, maps_prefix)
    ::Opal::Sprockets::SourceMapHeaderPatch.inject!(maps_prefix)
    Rack::Builder.app do
      not_found = lambda { |env| [404, {}, []] }
      use Rack::Deflater
      use Rack::ShowExceptions
      map(maps_prefix) do
        use Rack::ConditionalGet
        use Rack::ETag
        run maps_app
      end
      map('/assets') { run @sprockets_env }
      run Rack::Static.new(not_found, root: server.public_root, urls: server.public_urls)
    end
  end

  def call(env)
    @app.call env
  end
end
