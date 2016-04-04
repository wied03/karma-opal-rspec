require_relative 'spec_helper'
require 'metadata_server'
require 'environment'
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
    sprockets = Karma::SprocketsServer::Environment.new load_paths, @temp_dir
    allow(Karma::SprocketsServer::MetadataServer).to receive(:default_roll_up_list).and_return default_roll_up_list
    Karma::SprocketsServer::MetadataServer.new(sprockets, roll_up_list)
  end

  let(:load_paths) { [] }
  let(:roll_up_list) { [] }
  let(:default_roll_up_list) { [:foobar] }
  let(:opal_base_dir) { Gem::Specification.find_all_by_name('opal').first.gem_dir }
  let(:opal_rspec_dir) { File.expand_path(File.join(File.dirname(__FILE__), '../../../lib', 'opal_rspec')) }
  let(:opal_dir) { File.join(opal_base_dir, 'opal') }
  let(:opal_stdlib) { File.join(opal_base_dir, 'stdlib') }
  let(:opal_lib) { File.join(opal_base_dir, 'lib') }

  describe '#call' do
    before { get '/metadata' }

    subject { JSON.parse(last_response.body) }

    context 'default roll up' do
      let(:default_roll_up_list) { [/dependent/] }

      it { is_expected.to eq({
                               'load_paths' => [opal_dir, opal_stdlib, opal_lib, @temp_dir, opal_rspec_dir],
                               rolled_up_files: %w(dependent_file)
                             }) }
      pending 'write this'
    end

    context 'custom roll up' do
      let(:roll_up_list) { [/dependent/] }

      pending 'write this'
    end

    context 'additional load paths' do
      pending 'write this'
    end
  end

  describe '::default_roll_up_list' do
    subject { Karma::SprocketsServer::MetadataServer.send(:default_roll_up_list) }

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
