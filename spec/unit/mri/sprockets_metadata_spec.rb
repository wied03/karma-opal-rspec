require_relative 'spec_helper'
require 'sprockets_metadata'
require 'opal/rspec/rake_task'

describe SprocketsMetadata do
  describe '::get_dependency_graph' do
    before do
      @temp_dir = Dir.mktmpdir
      @current_dir = Dir.pwd
      Dir.chdir @temp_dir
    end

    after do
      Dir.chdir @current_dir
      FileUtils.rm_rf @temp_dir
    end

    def create_dummy_spec_files(*files)
      files.each do |file|
        FileUtils.mkdir_p File.dirname(file)
        FileUtils.touch file
      end
    end

    def absolute_path(file)
      File.join(@temp_dir, file)
    end

    let(:sprockets_env) do
      original_env = Opal::RSpec::SprocketsEnvironment.new pattern='**/*.rb',
                                                           exclude_pattern=nil,
                                                           files=nil,
                                                           default_path=@temp_dir
      original_env.add_spec_paths_to_sprockets
      original_env.cached
    end

    subject { SprocketsMetadata.get_dependency_graph sprockets_env, files }

    context 'no other dependencies' do
      before do
        create_dummy_spec_files 'single_file.rb'
      end

      let(:files) { %w{single_file} }

      it { is_expected.to eq([
                                 {
                                     filename: absolute_path('single_file.rb'),
                                     logical_path: 'single_file.js',
                                     dependencies: []
                                 }
                             ]) }
    end

    context '1 level of dependencies, 2 files' do
      before do
        create_dummy_spec_files 'single_file.rb', 'other_file.rb'
        File.write absolute_path('single_file.rb'), 'require "other_file"'
      end

      let(:files) { %w{single_file} }

      it { is_expected.to eq([
                                 {
                                     filename: absolute_path('single_file.rb'),
                                     logical_path: 'single_file.js',
                                     dependencies: [
                                         {
                                             filename: absolute_path('other_file.rb'),
                                             logical_path: 'other_file.self.js',
                                             dependencies: []
                                         }
                                     ]
                                 }
                             ]) }
    end

    context 'nested dependencies' do
      before do
        create_dummy_spec_files 'single_file.rb', 'level2.rb', 'level3.rb'
        File.write absolute_path('single_file.rb'), 'require "level2"'
        File.write absolute_path('level2.rb'), 'require "level3"'
      end

      let(:files) { %w{single_file} }

      it { is_expected.to eq([
                                 {
                                     filename: absolute_path('single_file.rb'),
                                     logical_path: 'single_file.js',
                                     dependencies: [
                                         {
                                             filename: absolute_path('level3.rb'),
                                             logical_path: 'level3.self.js',
                                             dependencies: []
                                         },
                                         # Sprockets doesn't do this in a nested way, but that's OK for what we need
                                         {
                                             filename: absolute_path('level2.rb'),
                                             logical_path: 'level2.self.js',
                                             dependencies: []
                                         }
                                     ]
                                 }
                             ]) }
    end

    context 'self-referential' do
      before do
        create_dummy_spec_files 'single_file.rb', 'other_file.rb'
        File.write absolute_path('single_file.rb'), 'require "other_file"'
        File.write absolute_path('other_file.rb'), 'require "single_file"'
      end

      let(:files) { %w{single_file} }

      it { is_expected.to eq([
                                 {
                                     filename: absolute_path('single_file.rb'),
                                     logical_path: 'single_file.js',
                                     dependencies: [
                                         {
                                             filename: absolute_path('other_file.rb'),
                                             logical_path: 'other_file.self.js',
                                             dependencies: []
                                         }
                                     ]
                                 }
                             ]) }
    end

    context 'sprockets style require' do
      before do
        create_dummy_spec_files 'single_file.js', 'other_file.rb'
        File.write absolute_path('single_file.js'), "//\n//= require other_file\n"
      end

      let(:files) { %w{single_file} }

      it { is_expected.to eq([
                                 {
                                     filename: absolute_path('single_file.js'),
                                     logical_path: 'single_file.js',
                                     dependencies: [
                                         {
                                             filename: absolute_path('other_file.rb'),
                                             logical_path: 'other_file.self.js',
                                             dependencies: []
                                         }
                                     ]
                                 }
                             ]) }
    end

    context 'shared dependencies' do
      before do
        create_dummy_spec_files 'single_file.rb', 'other_file.rb', 'third_file.rb'
        File.write absolute_path('single_file.rb'), 'require "other_file"'
        File.write absolute_path('third_file.rb'), 'require "other_file"'
      end

      let(:files) { %w{single_file third_file} }

      it { is_expected.to eq([
                                 {
                                     filename: absolute_path('single_file.rb'),
                                     logical_path: 'single_file.js',
                                     dependencies: [
                                         {
                                             filename: absolute_path('other_file.rb'),
                                             logical_path: 'other_file.self.js',
                                             dependencies: []
                                         }
                                     ]
                                 },
                                 {
                                     filename: absolute_path('third_file.rb'),
                                     logical_path: 'third_file.js',
                                     dependencies: [
                                         {
                                             filename: absolute_path('other_file.rb'),
                                             logical_path: 'other_file.self.js',
                                             dependencies: []
                                         }
                                     ]
                                 }
                             ]) }
    end
  end
end
