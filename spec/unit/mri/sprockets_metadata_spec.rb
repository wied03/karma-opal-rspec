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

    RSpec::Matchers.define :have_graph do |expected|
      match do |actual|
        actual_keys = actual[:file_mapping].keys
        expected_keys = expected[:file_mapping].keys
        @matcher = eq(expected_keys)
        # Test hash order
        next nil unless @matcher.matches? actual_keys
        @matcher = eq(expected)
        @matcher.matches? actual
      end

      failure_message do
        @matcher.failure_message
      end
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

      it { is_expected.to have_graph({
                                         file_mapping: {
                                             'single_file.js' => absolute_path('single_file.rb')
                                         },
                                         dependencies: {
                                             'single_file.js' => []
                                         }
                                     }) }
    end

    context '1 level of 2 dependencies' do
      before do
        create_dummy_spec_files 'single_file.rb', 'other_file.rb'
        File.write absolute_path('single_file.rb'), 'require "other_file"'
      end

      let(:files) { %w{single_file} }

      it { is_expected.to have_graph({
                                         file_mapping: {
                                             'other_file.js' => absolute_path('other_file.rb'),
                                             'single_file.js' => absolute_path('single_file.rb')
                                         },
                                         dependencies: {
                                             'single_file.js' => %w{other_file.js},
                                             'other_file.js' => []
                                         }
                                     }) }
    end

    context 'nested dependencies' do
      before do
        create_dummy_spec_files 'single_file.rb', 'level2.rb', 'level3.rb'
        File.write absolute_path('single_file.rb'), 'require "level2"'
        File.write absolute_path('level2.rb'), 'require "level3"'
      end

      let(:files) { %w{single_file} }

      it { is_expected.to have_graph({
                                         file_mapping: {
                                             'level3.js' => absolute_path('level3.rb'),
                                             'level2.js' => absolute_path('level2.rb'),
                                             'single_file.js' => absolute_path('single_file.rb')
                                         },
                                         dependencies: {
                                             'single_file.js' => %w{level3.js level2.js},
                                             'level3.js' => [],
                                             'level2.js' => %w{level3.js}
                                         }
                                     }) }
    end

    context 'self-referential' do
      before do
        create_dummy_spec_files 'single_file.rb', 'other_file.rb'
        File.write absolute_path('single_file.rb'), 'require "other_file"'
        File.write absolute_path('other_file.rb'), 'require "single_file"'
      end

      let(:files) { %w{single_file} }

      subject { lambda { SprocketsMetadata.get_dependency_graph sprockets_env, files } }

      it { is_expected.to raise_exception 'Circular dependency, one of ["single_file.js", "other_file.js"] refers to single_file.js and single_file.js refers to one of those files.' }
    end

    context 'back reference' do
      before do
        create_dummy_spec_files 'single_file.rb', 'other_file.rb', 'third_file.rb'
        File.write absolute_path('single_file.rb'), 'require "other_file"'
        File.write absolute_path('third_file.rb'), 'require "single_file"'
      end

      let(:files) { %w{single_file third_file} }

      it { is_expected.to have_graph({
                                         file_mapping: {
                                             'other_file.js' => absolute_path('other_file.rb'),
                                             'single_file.js' => absolute_path('single_file.rb'),
                                             'third_file.js' => absolute_path('third_file.rb')
                                         },
                                         dependencies: {
                                             'single_file.js' => %w{other_file.js},
                                             'other_file.js' => [],
                                             'third_file.js' => %w{other_file.js single_file.js}
                                         }
                                     }) }
    end

    context 'sprockets style require' do
      before do
        create_dummy_spec_files 'single_file.js', 'other_file.rb'
        File.write absolute_path('single_file.js'), "//\n//= require other_file\n"
      end

      let(:files) { %w{single_file} }

      it { is_expected.to have_graph({
                                         file_mapping: {
                                             'other_file.js' => absolute_path('other_file.rb'),
                                             'single_file.js' => absolute_path('single_file.js')
                                         },
                                         dependencies: {
                                             'single_file.js' => %w{other_file.js},
                                             'other_file.js' => [],
                                         }
                                     }) }
    end

    context 'multiple files' do
      context 'shared dependencies' do
        before do
          create_dummy_spec_files 'single_file.rb', 'other_file.rb', 'third_file.rb'
          File.write absolute_path('single_file.rb'), 'require "other_file"'
          File.write absolute_path('third_file.rb'), 'require "other_file"'
        end

        let(:files) { %w{single_file third_file} }

        it { is_expected.to have_graph({
                                           file_mapping: {
                                               'other_file.js' => absolute_path('other_file.rb'),
                                               'single_file.js' => absolute_path('single_file.rb'),
                                               'third_file.js' => absolute_path('third_file.rb')
                                           },
                                           dependencies: {
                                               'single_file.js' => %w{other_file.js},
                                               'other_file.js' => [],
                                               'third_file.js' => %w{other_file.js},
                                           }
                                       }) }
      end

      context 'each has different dependencies' do
        before do
          create_dummy_spec_files 'single_file.rb', 'other_file.rb', 'third_file.rb', 'yet_another_file.rb'
          File.write absolute_path('single_file.rb'), 'require "other_file"'
          File.write absolute_path('third_file.rb'), 'require "yet_another_file"'
        end

        let(:files) { %w{single_file third_file} }

        it { is_expected.to have_graph({
                                           file_mapping: {
                                               'other_file.js' => absolute_path('other_file.rb'),
                                               'single_file.js' => absolute_path('single_file.rb'),
                                               'yet_another_file.js' => absolute_path('yet_another_file.rb'),
                                               'third_file.js' => absolute_path('third_file.rb')
                                           },
                                           dependencies: {
                                               'single_file.js' => %w{other_file.js},
                                               'other_file.js' => [],
                                               'third_file.js' => %w{yet_another_file.js},
                                               'yet_another_file.js' => [],
                                           }
                                       }) }
      end
    end
  end

  describe '::get_metadata' do
    let(:roll_up_list) { [] }
    let(:watch) { false }
    subject { SprocketsMetadata.get_metadata dependency_graph, roll_up_list, watch }

    context 'no dependencies' do
      let(:dependency_graph) do
        {
            file_mapping: {
                'file1.js' => '/some/dir/file1.rb',
                'file2.js' => '/some/dir/file2.rb'
            },
            dependencies: {
                'file1.js' => [],
                'file2.js' => []
            }
        }
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

    context 'dependencies' do
      let(:dependency_graph) do
        {
            file_mapping: {
                'file3.js' => '/some/dir/file3.rb',
                'file1.js' => '/some/dir/file1.rb',
                'file2.js' => '/some/dir/file2.rb'
            },
            dependencies: {
                'file1.js' => ['file3.js'],
                'file2.js' => [],
                'file3.js' => []
            }
        }
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

    context 'watches enabled' do
      let(:watch) { true }

      let(:dependency_graph) do
        {
            file_mapping: {
                'file3.js' => '/some/dir/file3.rb',
                'file1.js' => '/some/dir/file1.rb',
                'file2.js' => '/some/dir/file2.rb'
            },
            dependencies: {
                'file1.js' => ['file3.js'],
                'file2.js' => [],
                'file3.js' => []
            }
        }
      end

      it { is_expected.to eq({
                                 '/some/dir/file3.rb' => {
                                     logical_path: 'file3.js',
                                     watch: true,
                                     roll_up: false
                                 },
                                 '/some/dir/file1.rb' => {
                                     logical_path: 'file1.js',
                                     watch: true,
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
        {
            file_mapping: {
                'file3.js' => '/some/dir/file3.rb',
                'file1.js' => '/some/dir/file1.rb',
                'file2.js' => '/some/dir/file2.rb'
            },
            dependencies: {
                'file1.js' => ['file3.js'],
                'file2.js' => [],
                'file3.js' => []
            }
        }
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

    context '2 files both have the same dependency and 1 is rolled up' do
      let(:roll_up_list) do
        %w{file1.rb}
      end

      let(:dependency_graph) do
        {
            file_mapping: {
                'file3.js' => '/some/dir/file3.rb',
                'file1.js' => '/some/dir/file1.rb',
                'file2.js' => '/some/dir/file2.rb'
            },
            dependencies: {
                'file1.js' => ['file3.js'],
                'file2.js' => ['file3.js'],
                'file3.js' => []
            }
        }
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

    context 'roll up asset comes later in list' do
      let(:roll_up_list) do
        %w{file1.rb}
      end

      let(:dependency_graph) do
        {
            file_mapping: {
                'file2.js' => '/some/dir/file2.rb',
                'file3.js' => '/some/dir/file3.rb',
                'file1.js' => '/some/dir/file1.rb',
            },
            dependencies: {
                'file1.js' => ['file3.js'],
                'file2.js' => [],
                'file3.js' => []
            }
        }
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
  end
end
