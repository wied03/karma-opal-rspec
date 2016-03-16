require_relative 'spec_helper'
require File.expand_path('../../../../lib/metadata_server.rb', __FILE__)
require 'rack/test'
require 'opal'

describe Karma::Opal::MetadataServer do
  include_context :temp_dir
  include Rack::Test::Methods

  before do
    create_dummy_spec_files 'single_file.rb', 'opal.rb', 'other_file.rb', 'dependent_file.rb'
    File.write absolute_path('single_file.rb'), 'require "opal"'
    File.write absolute_path('other_file.rb'), "require 'opal'\nFOO=456"
    File.write absolute_path('dependent_file.rb'), "require 'single_file'"
    File.write absolute_path('opal.rb'), 'HOWDY = 123'
  end

  let(:app) do
    sprockets = Sprockets::Environment.new
    ::Opal.paths.each { |p| sprockets.append_path(p) }
    sprockets.append_path @temp_dir
    allow(SprocketsMetadata).to receive(:default_roll_up_list).and_return default_roll_up_list
    Karma::Opal::MetadataServer.new(sprockets, roll_up_list)
  end

  let(:roll_up_list) { [] }
  let(:default_roll_up_list) { [] }

  before do
    # TODO: Remove exclude_self, derive watch from whether it's a GEM
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

  context 'single_file' do
    let(:requested_files) { absolute_path('single_file.rb') }

    it { is_expected.to eq(requested_files => { 'logical_path' => 'single_file.js', 'roll_up' => false }) }

    context 'with dependencies' do
      let(:requested_files) { absolute_path('dependent_file.rb') }

      it do
        is_expected.to eq({
                            absolute_path('single_file.rb') => { 'logical_path' => 'single_file.js', 'roll_up' => false },
                            absolute_path('dependent_file.rb') => { 'logical_path' => 'dependent_file.js', 'roll_up' => false }
                          })
      end

      context 'exclude self' do
        let(:exclude_self) { true }

        it do
          is_expected.to eq({
                              absolute_path('single_file.rb') => { 'logical_path' => 'single_file.js', 'roll_up' => false }
                            })
        end
      end
    end
  end

  context 'roll up' do
    let(:requested_files) { absolute_path('dependent_file.rb') }

    context 'custom' do
      let(:roll_up_list) { [/dependent/] }

      it { is_expected.to eq(absolute_path('dependent_file.rb') => { 'logical_path' => 'dependent_file.js', 'roll_up' => true }) }
    end

    context 'default' do
      let(:default_roll_up_list) { [/dependent/] }

      it { is_expected.to eq(absolute_path('dependent_file.rb') => { 'logical_path' => 'dependent_file.js', 'roll_up' => true }) }
    end
  end

  context 'multiple files' do
    let(:requested_files) { [absolute_path('single_file.rb'), absolute_path('other_file.rb')] }

    it do
      is_expected.to eq({
                          absolute_path('single_file.rb') => { 'logical_path' => 'single_file.js', 'roll_up' => false },
                          absolute_path('other_file.rb') => { 'logical_path' => 'other_file.js', 'roll_up' => false }
                        })
    end
  end
end
