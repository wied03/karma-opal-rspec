require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'opal'

describe 'rack server' do
  include_context :temp_dir
  include Rack::Test::Methods

  let(:mri_requires) { '' }
  let(:rails_env) { nil } # in case travis or local env has something here

  let(:app) do
    config_path = File.expand_path('../../../../lib/rack_server.ru', __FILE__)
    ENV['OPAL_LOAD_PATH'] = ''
    ENV['OPAL_DEFAULT_PATH'] = @temp_dir
    ENV['MRI_REQUIRES'] = mri_requires
    ENV['RAILS_ENV'] = rails_env
    Rack::Builder.new_from_string(File.read(config_path))
  end

  def fetch_asset(asset)
    get "/assets/#{asset}.js?body=1"
  end

  describe '#call' do
    before do
      create_dummy_spec_files 'single_file.rb', 'opal.rb', 'other_file.rb', 'dependent_file.rb'
      File.write absolute_path('single_file.rb'), 'require "opal"'
      File.write absolute_path('other_file.rb'), "require 'opal'\nFOO=456"
      File.write absolute_path('dependent_file.rb'), "require 'single_file'"
      File.write absolute_path('opal.rb'), 'HOWDY = 123'
    end

    describe 'root directory' do
      pending 'write this, should give 404'
    end

    # TODO: Move this to its own unit test class
    describe 'metadata' do
      before do
        contents = {
          files: [*requested_files],
          watch: watch,
          exclude_self: exclude_self
        }
        post '/metadata', contents.to_json
      end

      subject { JSON.parse(last_response.body) }

      let(:watch) { false }
      let(:exclude_self) { false }

      describe 'single_file' do
        let(:requested_files) { absolute_path('single_file.rb') }

        context 'watch on' do
          let(:watch) { true }

          it { is_expected.to eq(requested_files => { 'logical_path' => 'single_file.js', 'watch' => true, 'roll_up' => false }) }
        end

        context 'exclude self' do
          let(:exclude_self) { true }
          let(:requested_files) { absolute_path('dependent_file.rb') }

          it { is_expected.to eq(requested_files => { 'logical_path' => 'single_file.js', 'watch' => false, 'roll_up' => false }) }
        end
      end

      context 'roll up' do
        pending 'write this'
      end

      describe 'other_file' do
        let(:requested_files) { absolute_path('other_file.rb') }

        it { is_expected.to eq(requested_files => { 'logical_path' => 'other_file.js', 'watch' => false, 'roll_up' => false }) }
      end

      context 'multiple files' do
        pending 'write this'
      end
    end

    it 'fetches an asset properly multiple times' do
      fetch_asset 'other_file'
      expect(last_response.body).to match(/'FOO', 456/)
      fetch_asset 'other_file'
      expect(last_response.body).to match(/'FOO', 456/)
    end

    context 'custom requires' do
      let(:mri_requires) { 'opal-browser,rake' }

      before do
        File.write absolute_path('single_file.rb'), "require 'opal'\nrequire 'browser'"
        fetch_asset 'single_file'
      end

      subject { last_response.body }

      it { is_expected.to_not include 'Sprockets::FileNotFound' }
      it { is_expected.to include 'require("browser");' }
    end

    context 'Bundler requires' do
      before do
        File.write absolute_path('single_file.rb'), "require 'opal-factory_girl'"
      end

      subject { last_response.body }

      context 'no Rails' do
        before do
          # Can't easily re-do bundler require, so mock it here
          allow(Bundler).to receive(:require) do
            Opal.reset_paths!
            Opal.use_gem 'opal-factory_girl'
          end
          fetch_asset 'single_file'
        end

        it { is_expected.to_not include 'Sprockets::FileNotFound' }
        it { is_expected.to include 'require("opal-factory_girl")' }
      end

      context 'Rails' do
        let(:rails_env) { 'TEST' }

        before do
          create_dummy_spec_files 'config/environment.rb'
          rails_double = double 'Rails'
          stub_const 'Rails', rails_double
          app_double = double 'Application'
          allow(rails_double).to receive(:application).and_return app_double
          assets = double 'Assets'
          allow(app_double).to receive(:assets).and_return assets
          allow(assets).to receive(:paths).and_return []
          Opal.reset_paths!
          # See mock in no Rails for why we're doing this
          expect(Bundler).to_not receive(:require)
          get '/assets/single_file.js?body=1'
        end

        it { is_expected.to include 'Sprockets::FileNotFound' }
        it { is_expected.to_not include 'require("opal-factory_girl")' }
      end
    end
  end
end
