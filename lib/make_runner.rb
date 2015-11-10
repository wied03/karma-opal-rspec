require 'opal/rspec'

# or use Opal::RSpec::SprocketsEnvironment.new(spec_pattern='spec/opal/**/*_spec.{rb,opal}') to customize the pattern
sprockets_env = Opal::RSpec::SprocketsEnvironment.new
Opal.paths.each {|p| sprockets_env.append_path p }
sprockets_env.add_spec_paths_to_sprockets

File.open ARGV[0], 'w' do |file|
  file << <<-EOF
  require 'opal'
  
  STUBBED_FILES = #{Opal::Processor.stubbed_files.to_a.inspect}  
  LOAD_PATHS = #{sprockets_env.paths.to_a.inspect}
  
  STUBBED_FILES.each {|f| Opal::Processor.stub_file f}
  LOAD_PATHS.each {|p| Opal.append_path p }
  
  source = File.read ARGV[0]
  puts Opal.compile(source)
  EOF
end
