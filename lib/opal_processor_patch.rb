require 'opal'

class Opal::Processor
  FILTER = %w(opal opal/base).freeze

  def allowed_context_path
    @allowed_path ||= Pathname.new(File.join(Gem::Specification.find_all_by_name('opal').first.gem_dir, 'opal'))
  end

  def is_opal_originating_asset?(context)
    context.pathname.ascend do |path|
      return true if path == allowed_context_path
    end
    false
  end

  def process_requires(requires, context)
    requires.each do |required|
      required = required.to_s.sub(sprockets_extnames_regexp, '')
      # If other rolled up assets do a "require 'opal'", we don't want to end up bundling a 2nd rolled up opal instance
      if is_opal_originating_asset?(context) || !FILTER.include?(required)
        context.require_asset required unless stubbed_files.include? required
      end
    end
  end
end
