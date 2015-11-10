require 'spec_helper'

describe 'something' do
  subject { 43 }

  context 'nested' do
    it { is_expected.to eq 42 }
  end
end
