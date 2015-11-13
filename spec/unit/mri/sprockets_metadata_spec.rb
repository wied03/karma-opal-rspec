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
        yield file if block_given?
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
      pending 'write this'
    end

    context '1 level of dependencies' do
      pending 'write this'
    end

    context 'nested dependencies' do
      pending 'write this'
    end

    context 'self-referential' do
      pending 'write this'
    end
  end
end
