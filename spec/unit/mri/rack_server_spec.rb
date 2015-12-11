require_relative 'spec_helper'
require 'rack'
require 'rack/test'

describe 'rack server' do
  include_context :temp_dir
  include Rack::Test::Methods

  let(:app) do
    config_path = File.expand_path('../../../../lib/rack_server.ru', __FILE__)
    karma_pattern = File.expand_path('**/*.rb')
    ENV['PATTERN'] = karma_pattern
    ENV['OPAL_LOAD_PATH'] = ''
    ENV['OPAL_DEFAULT_PATH'] = @temp_dir
    ENV['RAILS_ENV'] = nil # in case travis or local env has something here
    Rack::Builder.new_from_string(File.read(config_path))
  end

  describe '#call' do
    before do
      create_dummy_spec_files 'single_file.rb', 'opal.rb', 'other_file.rb'
      File.write absolute_path('single_file.rb'), 'require "opal"'
      File.write absolute_path('other_file.rb'), "require 'opal'\nFOO=456"
      File.write absolute_path('opal.rb'), 'HOWDY = 123'
    end

    it 'fetches an asset properly' do
      get '/assets/other_file.js?body=1'
      expect(last_response.body).to match /'FOO', 456/
      get '/assets/other_file.js?body=1'
      expect(last_response.body).to match /'FOO', 456/
    end
  end
end
