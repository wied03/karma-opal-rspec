require_relative 'spec_helper'
require 'metadata_server'
require 'environment'
require 'opal'
Bundler.require

describe Karma::SprocketsServer::MetadataServer do
  include_context :temp_dir

  before do
    create_dummy_spec_files 'stuff/impl/test_dep.rb', 'stuff/impl/test_dep_dep.rb', 'spec/stuff_spec.rb'
    File.write absolute_path('stuff/impl/test_dep.rb'), 'require "impl/test_dep_dep"'
    File.write absolute_path('stuff/impl/test_dep_dep.rb'), 'require "opal"'
    File.write absolute_path('spec/stuff_spec.rb'), 'require "impl/test_dep"; puts "Howdy"'
  end

  let(:app) do
    sprockets = Karma::SprocketsServer::Environment.new load_paths, 'spec'
    Karma::SprocketsServer::MetadataServer.new(sprockets, roll_up_list, patterns)
  end

  let(:patterns) { 'spec/**/*_spec.rb' }
  let(:load_paths) { %w(stuff) }
  let(:load_path_absolute) { File.expand_path load_paths[0] }
  let(:roll_up_list) { [] }
  let(:opal_base_dir) { Gem::Specification.find_all_by_name('opal').first.gem_dir }
  let(:karma_opal_rspec_dir) { File.expand_path(File.join(File.dirname(__FILE__), '../../../lib', 'opal_rspec')) }
  let(:opal_dir) { File.join(opal_base_dir, 'opal') }
  let(:opal_stdlib) { File.join(opal_base_dir, 'stdlib') }
  let(:opal_lib) { File.join(opal_base_dir, 'lib') }
  let(:opal_rspec_base) { Gem::Specification.find_all_by_name('opal-rspec').first.gem_dir }
  let(:opal_rspec_opal) { File.join(opal_rspec_base, 'opal') }

  describe '#call' do
    subject do
      result = app.call
      raw = JSON.parse(result[2][0])
      # symbolize for ease of matching
      Hash[raw.map { |k, v| [k.to_sym, v] }]
    end

    context 'default roll up' do
      it {
        is_expected.to include(load_paths: include(opal_dir,
                                                   opal_stdlib,
                                                   opal_lib,
                                                   opal_rspec_opal,
                                                   load_path_absolute,
                                                   karma_opal_rspec_dir),
                               roll_ups: include(File.join(opal_dir, 'opal.rb'),
                                                 File.join(opal_rspec_opal, 'opal-rspec.rb')))
      }
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
