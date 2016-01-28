require 'browser'

describe 'document' do
  subject { $document }

  it { is_expected.to respond_to :body }
end
