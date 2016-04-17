require 'opal'
require 'opal-rspec'

destination_filename = File.join(File.dirname(__FILE__), '../vendor', "opal-#{Opal::VERSION}-rspec-#{Opal::RSpec::VERSION}.js")

unless File.exist? destination_filename
  begin
    Opal.append_path File.dirname(__FILE__)
    is_opal_09 = Opal::VERSION.include?('0.9')
    stubs = is_opal_09 ? Opal::Processor.stubbed_files : Opal::Config.stubbed_files
    # no accidental opal dupes in our RSpec code, etc.
    stubs += %w(opal opal/mini opal/full)
    rspec_builder = Opal::Builder.new(stubs: stubs)
    File.open destination_filename, 'w' do |file|
      go_arity = { arity_check: !is_opal_09 } # arity checking not supported with opal-rspec on 0.9
      opal_builder = Opal::Builder.new
      opal_src = opal_builder.build 'opal', go_arity
      file << opal_src
      spec_source = rspec_builder.build 'opal-rspec', { dynamic_require_severity: :ignore }.merge(go_arity)
      file << spec_source
      reporter = rspec_builder.build 'karma_reporter', go_arity
      file << reporter
    end
  rescue
    File.delete destination_filename if File.exist?(destination_filename)
    raise
  end
end

# for the JS side
puts File.expand_path(destination_filename)
