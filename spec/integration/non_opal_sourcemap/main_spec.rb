require 'jquery.min'

describe 'something' do
  subject { 42 }

  context 'nested' do
    it { is_expected.to eq 42 }
  end
end
