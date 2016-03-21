require 'react'

describe 'GEM Pure JS' do
  subject { `React.version` }

  it { is_expected.to include '0.14' }
end
