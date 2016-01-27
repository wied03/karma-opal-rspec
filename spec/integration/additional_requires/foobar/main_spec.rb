require 'browser'

describe 'document' do
  subject { $document }

  it { is_expected.to be_a String }
end
