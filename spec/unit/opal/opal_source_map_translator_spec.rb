require 'opalSourceMapTranslator'
require 'native'

describe 'opalSourceMapTranslator' do
  subject do
    func = `require(process.cwd()+'/lib/opalSourceMapTranslator')`
    native_source_map = existing_source_map.to_n
    result = `#{func}(#{native_source_map}, #{request_url})`
    Hash.new(result)
  end

  context 'absolute path' do
    let(:existing_source_map) do
      {
        version: 3,
        file: nil,
        mappings: 'lorem ipsum',
        sources: ['/__OPAL_SOURCE_MAPS__/karma_formatter.rb'],
        names: []
      }
    end
    let(:request_url) { '/absolute/Users/brady/code/Ruby/opal/repos_NOCRASHPLAN/karma-opal-rspec/lib/karma_formatter.js.map' }

    it do
      is_expected.to eq(version: 3,
                        file: '/absolute/Users/brady/code/Ruby/opal/repos_NOCRASHPLAN/karma-opal-rspec/lib/karma_formatter.js',
                        mappings: 'lorem ipsum',
                        sources: ['/absolute/Users/brady/code/Ruby/opal/repos_NOCRASHPLAN/karma-opal-rspec/lib/karma_formatter.rb'],
                        names: [])
    end
  end

  context 'project relative path' do
    let(:existing_source_map) do
      {
        version: 3,
        file: nil,
        mappings: 'lorem ipsum',
        sources: ['/__OPAL_SOURCE_MAPS__/main_spec.rb'],
        names: []
      }
    end
    let(:request_url) { '/base/spec/main_spec.js.map' }

    it do
      is_expected.to eq(version: 3,
                        file: '/base/spec/main_spec.js',
                        mappings: 'lorem ipsum',
                        sources: ['/base/spec/main_spec.rb'],
                        names: [])
    end
  end
end
