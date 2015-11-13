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

      it { is_expected.to eq [
                                 SprocketsMetadata::Asset.new(absolute_path('single_file.rb'),
                                                              'single_file.js',
                                                              [])
                             ] }
    end

    context '1 level of dependencies, 2 files' do
      before do
        create_dummy_spec_files 'single_file.rb', 'other_file.rb'
        File.write absolute_path('single_file.rb'), 'require "other_file"'
      end

      let(:files) { %w{single_file} }

      it { is_expected.to eq [
                                 SprocketsMetadata::Asset.new(absolute_path('single_file.rb'),
                                                              'single_file.js',
                                                              [
                                                                  SprocketsMetadata::Asset.new(absolute_path('other_file.rb'),
                                                                                               'other_file.self.js',
                                                                                               [])
                                                              ])
                             ] }
    end

    context 'nested dependencies' do
      before do
        create_dummy_spec_files 'single_file.rb', 'level2.rb', 'level3.rb'
        File.write absolute_path('single_file.rb'), 'require "level2"'
        File.write absolute_path('level2.rb'), 'require "level3"'
      end

      let(:files) { %w{single_file} }

      it { is_expected.to eq [
                                 SprocketsMetadata::Asset.new(absolute_path('single_file.rb'),
                                                              'single_file.js',
                                                              [
                                                                  SprocketsMetadata::Asset.new(absolute_path('level3.rb'),
                                                                                               'level3.self.js',
                                                                                               []),
                                                                  SprocketsMetadata::Asset.new(absolute_path('level2.rb'),
                                                                                               'level2.self.js',
                                                                                               [])
                                                              ])
                             ] }
    end

    context 'self-referential' do
      before do
        create_dummy_spec_files 'single_file.rb', 'other_file.rb'
        File.write absolute_path('single_file.rb'), 'require "other_file"'
        File.write absolute_path('other_file.rb'), 'require "single_file"'
      end

      let(:files) { %w{single_file} }

      it { is_expected.to eq [
                                 SprocketsMetadata::Asset.new(absolute_path('single_file.rb'),
                                                              'single_file.js',
                                                              [
                                                                  SprocketsMetadata::Asset.new(absolute_path('other_file.rb'),
                                                                                               'other_file.self.js',
                                                                                               [])
                                                              ])
                             ] }
    end

    context 'sprockets style require' do
      before do
        create_dummy_spec_files 'single_file.js', 'other_file.rb'
        File.write absolute_path('single_file.js'), "//\n//= require other_file\n"
      end

      let(:files) { %w{single_file} }

      it { is_expected.to eq [
                                 SprocketsMetadata::Asset.new(absolute_path('single_file.js'),
                                                              'single_file.js',
                                                              [
                                                                  SprocketsMetadata::Asset.new(absolute_path('other_file.rb'),
                                                                                               'other_file.self.js',
                                                                                               [])
                                                              ])
                             ] }
    end

    context 'shared dependencies' do
      before do
        create_dummy_spec_files 'single_file.rb', 'other_file.rb', 'third_file.rb'
        File.write absolute_path('single_file.rb'), 'require "other_file"'
        File.write absolute_path('third_file.rb'), 'require "other_file"'
      end

      let(:files) { %w{single_file third_file} }

      it { is_expected.to eq [
                                 SprocketsMetadata::Asset.new(absolute_path('single_file.rb'),
                                                              'single_file.js',
                                                              [
                                                                  SprocketsMetadata::Asset.new(absolute_path('other_file.rb'),
                                                                                               'other_file.self.js',
                                                                                               [])
                                                              ]),
                                 SprocketsMetadata::Asset.new(absolute_path('third_file.rb'),
                                                              'third_file.js',
                                                              [
                                                                  SprocketsMetadata::Asset.new(absolute_path('other_file.rb'),
                                                                                               'other_file.self.js',
                                                                                               [])
                                                              ])
                             ] }
    end
  end

  describe '::get_metadata' do
    let(:roll_up_list) { [] }
    let(:watch_list) { [] }
    subject { SprocketsMetadata.get_metadata dependency_graph, roll_up_list, watch_list }

    context 'no dependencies' do
      context 'no dupes' do
        let(:dependency_graph) do
          [
              SprocketsMetadata::Asset.new('/some/dir/file1.rb',
                                           'file1.js',
                                           []),
              SprocketsMetadata::Asset.new('/some/dir/file2.rb',
                                           'file2.js',
                                           [])
          ]
        end

        it { is_expected.to eq({
                                   '/some/dir/file1.rb' => {
                                       logical_path: 'file1.js',
                                       watch: false,
                                       roll_up: false
                                   },
                                   '/some/dir/file2.rb' => {
                                       logical_path: 'file2.js',
                                       watch: false,
                                       roll_up: false
                                   }
                               }) }
      end

      context 'dupes' do
        let(:dependency_graph) do
          [
              SprocketsMetadata::Asset.new('/some/dir/file1.rb',
                                           'file1.js',
                                           []),
              SprocketsMetadata::Asset.new('/some/dir/file2.rb',
                                           'file2.js',
                                           []),
              SprocketsMetadata::Asset.new('/some/dir/file1.rb',
                                           'file1.js',
                                           [])
          ]
        end

        it { is_expected.to eq({
                                   '/some/dir/file1.rb' => {
                                       logical_path: 'file1.js',
                                       watch: false,
                                       roll_up: false
                                   },
                                   '/some/dir/file2.rb' => {
                                       logical_path: 'file2.js',
                                       watch: false,
                                       roll_up: false
                                   }
                               }) }
      end
    end

    context 'dependencies' do
      context 'no dupes' do
        let(:dependency_graph) do
          [
              SprocketsMetadata::Asset.new('/some/dir/file1.rb',
                                           'file1.js',
                                           [
                                               SprocketsMetadata::Asset.new('/some/dir/file3.rb',
                                                                            'file3.js',
                                                                            [])
                                           ]),
              SprocketsMetadata::Asset.new('/some/dir/file2.rb',
                                           'file2.js',
                                           [])
          ]
        end

        it { is_expected.to eq({
                                   '/some/dir/file3.rb' => {
                                       logical_path: 'file3.js',
                                       watch: false,
                                       roll_up: false
                                   },
                                   '/some/dir/file1.rb' => {
                                       logical_path: 'file1.js',
                                       watch: false,
                                       roll_up: false
                                   },
                                   '/some/dir/file2.rb' => {
                                       logical_path: 'file2.js',
                                       watch: false,
                                       roll_up: false
                                   }
                               }) }
      end

      context 'dupes' do
        let(:dependency_graph) do
          [
              SprocketsMetadata::Asset.new('/some/dir/file1.rb',
                                           'file1.js',
                                           [
                                               SprocketsMetadata::Asset.new('/some/dir/file3.rb',
                                                                            'file3.js',
                                                                            [])
                                           ]),
              SprocketsMetadata::Asset.new('/some/dir/file2.rb',
                                           'file2.js',
                                           [
                                               SprocketsMetadata::Asset.new('/some/dir/file3.rb',
                                                                            'file3.js',
                                                                            [])
                                           ])
          ]
        end

        it { is_expected.to eq({
                                   '/some/dir/file3.rb' => {
                                       logical_path: 'file3.js',
                                       watch: false,
                                       roll_up: false
                                   },
                                   '/some/dir/file1.rb' => {
                                       logical_path: 'file1.js',
                                       watch: false,
                                       roll_up: false
                                   },
                                   '/some/dir/file2.rb' => {
                                       logical_path: 'file2.js',
                                       watch: false,
                                       roll_up: false
                                   }
                               }) }
      end
    end

    context 'watches enabled' do
      let(:watch_list) do
        %w(file2.rb file3.rb)
      end

      let(:dependency_graph) do
        [
            SprocketsMetadata::Asset.new('/some/dir/file1.rb',
                                         'file1.js',
                                         [
                                             SprocketsMetadata::Asset.new('/some/dir/file3.rb',
                                                                          'file3.js',
                                                                          [])
                                         ]),
            SprocketsMetadata::Asset.new('/some/dir/file2.rb',
                                         'file2.js',
                                         [])
        ]
      end

      it { is_expected.to eq({
                                 '/some/dir/file3.rb' => {
                                     logical_path: 'file3.js',
                                     watch: true,
                                     roll_up: false
                                 },
                                 '/some/dir/file1.rb' => {
                                     logical_path: 'file1.js',
                                     watch: false,
                                     roll_up: false
                                 },
                                 '/some/dir/file2.rb' => {
                                     logical_path: 'file2.js',
                                     watch: true,
                                     roll_up: false
                                 }
                             }) }
    end

    context 'roll up enabled' do
      let(:roll_up_list) do
        %w{file1.rb}
      end

      let(:dependency_graph) do
        [
            SprocketsMetadata::Asset.new('/some/dir/file1.rb',
                                         'file1.js',
                                         [
                                             SprocketsMetadata::Asset.new('/some/dir/file3.rb',
                                                                          'file3.js',
                                                                          [])
                                         ]),
            SprocketsMetadata::Asset.new('/some/dir/file2.rb',
                                         'file2.js',
                                         [])
        ]
      end

      it { is_expected.to eq({
                                 '/some/dir/file1.rb' => {
                                     logical_path: 'file1.js',
                                     watch: false,
                                     roll_up: true
                                 },
                                 '/some/dir/file2.rb' => {
                                     logical_path: 'file2.js',
                                     watch: false,
                                     roll_up: false
                                 }
                             }) }
    end

    context 'dupes between rolled up and non-rolled up' do
      let(:roll_up_list) do
        %w{file1.rb}
      end

      let(:dependency_graph) do
        [
            SprocketsMetadata::Asset.new('/some/dir/file1.rb',
                                         'file1.js',
                                         [
                                             SprocketsMetadata::Asset.new('/some/dir/file3.rb',
                                                                          'file3.js',
                                                                          [])
                                         ]),
            SprocketsMetadata::Asset.new('/some/dir/file2.rb',
                                         'file2.js',
                                         []),
            SprocketsMetadata::Asset.new('/some/dir/file3.rb',
                                         'file3.js',
                                         [])
        ]
      end


      it { is_expected.to eq({
                                 '/some/dir/file1.rb' => {
                                     logical_path: 'file1.js',
                                     watch: false,
                                     roll_up: true
                                 },
                                 '/some/dir/file2.rb' => {
                                     logical_path: 'file2.js',
                                     watch: false,
                                     roll_up: false
                                 },
                                 '/some/dir/file3.rb' => {# Unless we disable caching, no easy way to get purely nested dependencies, so we'll see these twice
                                                          logical_path: 'file3.js',
                                                          watch: false,
                                                          roll_up: false
                                 }
                             }) }
    end

    context 'roll up asset comes later in list' do
      let(:roll_up_list) do
        %w{file1.rb}
      end

      let(:dependency_graph) do
        [
            SprocketsMetadata::Asset.new('/some/dir/file2.rb',
                                         'file2.js',
                                         []),
            SprocketsMetadata::Asset.new('/some/dir/file3.rb',
                                         'file3.js',
                                         []),
            SprocketsMetadata::Asset.new('/some/dir/file1.rb',
                                         'file1.js',
                                         [
                                             SprocketsMetadata::Asset.new('/some/dir/file3.rb',
                                                                          'file3.js',
                                                                          [])
                                         ]),
        ]
      end

      it { is_expected.to eq({
                                 '/some/dir/file1.rb' => {
                                     logical_path: 'file1.js',
                                     watch: false,
                                     roll_up: true
                                 },
                                 '/some/dir/file2.rb' => {
                                     logical_path: 'file2.js',
                                     watch: false,
                                     roll_up: false
                                 },
                                 '/some/dir/file3.rb' => {# Unless we disable caching, no easy way to get purely nested dependencies, so we'll see these twice
                                                          logical_path: 'file3.js',
                                                          watch: false,
                                                          roll_up: false
                                 }
                             }) }
    end
  end
end
