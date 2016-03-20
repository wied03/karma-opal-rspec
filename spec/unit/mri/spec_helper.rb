$LOAD_PATH << File.expand_path('../../../../lib/sprockets_server', __FILE__)

RSpec.shared_context :temp_dir do
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
end

RSpec.configure do |config|
  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true
end
