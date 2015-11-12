require 'class_under_test'

describe ClassUnderTest do
  subject { ClassUnderTest.howdy }

  context 'nested' do
    it { is_expected.to eq 42 }
  end
end
