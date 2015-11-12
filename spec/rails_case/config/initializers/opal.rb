Rails.application.configure do
  config.app_generators.javascript_engine :opal
  Opal.append_path 'app/view_models'

  app = Rails.application
  Opal.paths.each do |path|
    app.assets.append_path path
  end

  conf = config
  app.routes.prepend do
    if Opal::Processor.source_map_enabled && conf.assets.compile && conf.assets.debug
      maps_prefix = '/__OPAL_SOURCE_MAPS__'
      maps_app = Opal::SourceMapServer.new(app.assets, maps_prefix)

      ::Opal::Sprockets::SourceMapHeaderPatch.inject!(maps_prefix)

      mount maps_app => maps_prefix
    end
  end
end
