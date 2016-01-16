require_relative 'spec_helper'
require_relative '../../../lib/opal_processor_patch'

describe Opal::Processor do
  describe ':#process_requires' do
    include_context :temp_dir

    def get_context(asset_name)
      pathname = Pathname(asset_name)
      filename = pathname.to_s
      environment = double(Sprockets::Environment,
                           cache: nil,
                           :[] => nil,
                           resolve: pathname.expand_path.to_s,
                           engines: double(keys: %w(.rb .js .opal)))
      double(Sprockets::Context,
             logical_path: asset_name,
             environment: environment,
             pathname: pathname,
             filename: filename,
             root_path: @temp_dir,
             is_a?: true
            )
    end

    let(:processor) do
      Opal::Processor.new { |_t| ruby_contents }
    end

    subject { processor.render(get_context(asset_name)) }

    context 'single file' do
      let(:asset_name) { 'foo.rb' }
      let(:ruby_contents) { "puts 'Hello, World!'\n" }

      it { is_expected.to match(/"Hello, World!"/) }
    end

    context 'rolled up file with Opal dependency' do
      before do
        opal_gem_dir = instance_double Gem::Specification
        allow(opal_gem_dir).to receive(:gem_dir).and_return('/the/gems_dir/opal-0.9')
        allow(Gem::Specification).to receive(:find_all_by_name).with('opal').and_return([opal_gem_dir])
        @opal_context = get_context('/the/gems_dir/opal-0.9/opal/opal.rb')
        @opal_processor = Opal::Processor.new { |_t| "require 'opal/base'" }
        @opal_base_context = get_context('/the/gems_dir/opal-0.9/opal/opal/opal/base.rb')
        @opal_base_processor = Opal::Processor.new { |_t| 'RUBY_LIB=1' }
        @foo_context = get_context('foo.rb')
        @foo_processor = Opal::Processor.new { |_t| "require 'opal'\nFOO=123" }
      end

      it 'renders the file without Opal' do
        expect(@foo_context).to_not receive(:require_asset).with('opal')
        rendered = @foo_processor.render(@foo_context)
        expect(rendered).to_not match(/OPAL_LIB/)
        expect(rendered).to match(/FOO/)
      end

      it 'opal to pass through' do
        expect(@opal_context).to receive(:require_asset).with('opal/base')
        rendered = @opal_processor.render(@opal_context)
        expect(rendered).to include 'opal/base'
        rendered = @opal_base_processor.render(@opal_base_context)
        expect(rendered).to include 'RUBY_LIB'
      end
    end
  end
end
