require 'opal'
require 'opal-rspec'

DESTINATION_DIR = 'tmp'
Dir.mkdir(DESTINATION_DIR) unless Dir.exist? DESTINATION_DIR
DESTINATION_FILENAME = File.join(DESTINATION_DIR, "opal-#{Opal::VERSION}-rspec-#{Opal::RSpec::VERSION}.js")
KARMA_REPORTER_FILENAME = 'karma_reporter.rb'

REPORTER_FILTER = [
  File.basename(DESTINATION_FILENAME),
  File.expand_path('../runner.js', __FILE__),
  'karma.js',
  'context.html'
]

unless File.exist? DESTINATION_FILENAME
  begin
    is_opal_09 = Opal::VERSION.include?('0.9')
    stubs = is_opal_09 ? Opal::Processor.stubbed_files : Opal::Config.stubbed_files
    # no accidental opal dupes in our RSpec code, etc.
    stubs += %w(opal opal/mini opal/full)
    rspec_builder = Opal::Builder.new(stubs: stubs)
    File.open DESTINATION_FILENAME, 'w' do |file|
      go_arity = { arity_check: !is_opal_09 } # arity checking not supported with opal-rspec on 0.9
      opal_builder = Opal::Builder.new
      opal_src = opal_builder.build 'opal', go_arity
      file << opal_src
      spec_source = rspec_builder.build 'opal-rspec', { dynamic_require_severity: :ignore }.merge(go_arity)
      file << spec_source
      reporter_src = File.read(File.join(File.dirname(__FILE__), KARMA_REPORTER_FILENAME))
      # we reference this filename in the reporter for stack trace filtering
      reporter_src.gsub!('THE_OPAL_RSPEC_PATH', REPORTER_FILTER.inspect)
      reporter = rspec_builder.build_str reporter_src, KARMA_REPORTER_FILENAME, go_arity
      file << reporter
    end
  rescue
    File.delete DESTINATION_FILENAME if File.exist?(DESTINATION_FILENAME)
    raise
  end
end

# for the JS side
puts File.expand_path(DESTINATION_FILENAME)
