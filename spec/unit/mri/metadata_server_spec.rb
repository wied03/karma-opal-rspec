require_relative 'spec_helper'
require 'metadata_server'
require 'rack/test'
require 'opal'

describe Karma::SprocketsServer::MetadataServer do
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
    allow(Karma::SprocketsServer::Metadata).to receive(:default_roll_up_list).and_return default_roll_up_list
    Karma::SprocketsServer::MetadataServer.new(sprockets, roll_up_list)
  end

  let(:roll_up_list) { [] }
  let(:default_roll_up_list) { [] }

  before do
    contents = {
      files: [*requested_files],
      watch: watch
    }
    post '/metadata', contents.to_json
  end

  subject { JSON.parse(last_response.body) }

  let(:watch) { false }

  context 'single_file' do
    let(:requested_files) { absolute_path('single_file.rb') }

    it { is_expected.to eq(requested_files => { 'logical_path' => 'single_file.js', 'roll_up' => false }) }

    context 'with dependencies' do
      let(:requested_files) { absolute_path('dependent_file.rb') }

      it do
        is_expected.to eq(absolute_path('single_file.rb') => { 'logical_path' => 'single_file.js', 'roll_up' => false },
                          absolute_path('dependent_file.rb') => { 'logical_path' => 'dependent_file.js', 'roll_up' => false })
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
      is_expected.to eq(absolute_path('single_file.rb') => { 'logical_path' => 'single_file.js', 'roll_up' => false },
                        absolute_path('other_file.rb') => { 'logical_path' => 'other_file.js', 'roll_up' => false })
    end
  end

  describe '::default_roll_up_list' do
    subject { Karma::SprocketsServer::Metadata.default_roll_up_list }

    context 'mocked' do
      before do
        stuff = double
        allow(Gem::Specification).to receive(:find_all_by_name).with('opal').and_return([stuff])
        allow(stuff).to receive(:gem_dir).and_return('/some/path/to/gems/opal')
      end

      it { is_expected.to eq [%r{/some/path/to/gems}] }
    end

    context 'real' do
      it { is_expected.to include(be_a(Regexp)) }
    end
  end
end
